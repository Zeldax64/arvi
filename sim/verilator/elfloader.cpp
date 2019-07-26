/*
  elfloader.cpp
  This is the same file from ETH's Ariane project with minor modifications.
*/

#include <fesvr/elf.h>
#include <fesvr/memif.h>

//#include <svdpi.h>

#include <cstring>
#include <string>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <assert.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <vector>
#include <map>
#include <iostream>

#include "elfloader.h"

// Using SHT_NOBITS define in order to get symbols eg. fromhost and tohost
// SHT_NOBITS is defined in riscv-fesvr <elf.h>
#define SHT_PROGBITS 0x1
#define SHT_GROUP 0x11

// address and size
std::vector<std::pair<reg_t, reg_t>> sections;
std::map<std::string, uint64_t> symbols;
// memory based address and content
std::map<reg_t, std::vector<uint8_t>> mems;
reg_t entry;
int section_index = 0;

void write (uint64_t address, uint64_t len, uint8_t* buf) {
    uint64_t datum;
    std::vector<uint8_t> mem;
    for (int i = 0; i < len; i++) {
        mem.push_back(buf[i]);
    }
    mems.insert(std::make_pair(address, mem));
}

// Communicate the section address and len
// Returns:
// 0 if there are no more sections
// 1 if there are more sections to load
char get_section (long long* address, long long* len) {
    if (section_index < sections.size()) {
      *address = sections[section_index].first;
      *len = sections[section_index].second;
      section_index++;
      return 1;
    } else return 0;
}

void read_section (long long address, char * buffer) {
    // get actual poitner
    char* buf = buffer;
    // check that the address points to a section
    assert(mems.count(address) > 0);
    // copy array
    int i = 0;

    for (auto &datum : mems.find(address)->second) {
      *((char *) buf + i) = datum;

      i++;
    }

}

void read_elf(const char* filename) {
    int fd = open(filename, O_RDONLY);
    struct stat s;
    assert(fd != -1);
    if (fstat(fd, &s) < 0)
    abort();
    size_t size = s.st_size;

    char* buf = (char*)mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
    assert(buf != MAP_FAILED);
    close(fd);

    assert(size >= sizeof(Elf64_Ehdr));
    const Elf64_Ehdr* eh64 = (const Elf64_Ehdr*)buf;
    assert(IS_ELF32(*eh64) || IS_ELF64(*eh64));

    std::vector<uint8_t> zeros;
    // Using global variable instead of local
    //std::map<std::string, uint64_t> symbols;

    #define LOAD_ELF(ehdr_t, phdr_t, shdr_t, sym_t) do { \
    ehdr_t* eh = (ehdr_t*)buf; \
    phdr_t* ph = (phdr_t*)(buf + eh->e_phoff); \
    entry = eh->e_entry; \
    assert(size >= eh->e_phoff + eh->e_phnum*sizeof(*ph)); \
    for (unsigned i = 0; i < eh->e_phnum; i++) { \
      if(ph[i].p_type == PT_LOAD && ph[i].p_memsz) { \
        if (ph[i].p_filesz) { \
          assert(size >= ph[i].p_offset + ph[i].p_filesz); \
          sections.push_back(std::make_pair(ph[i].p_paddr, ph[i].p_memsz)); \
          write(ph[i].p_paddr, ph[i].p_filesz, (uint8_t*)buf + ph[i].p_offset); \
        } \
        zeros.resize(ph[i].p_memsz - ph[i].p_filesz); \
      } \
    } \
    shdr_t* sh = (shdr_t*)(buf + eh->e_shoff); \
    assert(size >= eh->e_shoff + eh->e_shnum*sizeof(*sh)); \
    assert(eh->e_shstrndx < eh->e_shnum); \
    assert(size >= sh[eh->e_shstrndx].sh_offset + sh[eh->e_shstrndx].sh_size); \
    char *shstrtab = buf + sh[eh->e_shstrndx].sh_offset; \
    unsigned strtabidx = 0, symtabidx = 0; \
    for (unsigned i = 0; i < eh->e_shnum; i++) { \
      unsigned max_len = sh[eh->e_shstrndx].sh_size - sh[i].sh_name; \
      if ((sh[i].sh_type & SHT_GROUP) && strcmp(shstrtab + sh[i].sh_name, ".strtab") != 0 && strcmp(shstrtab + sh[i].sh_name, ".shstrtab") != 0) \
      assert(strnlen(shstrtab + sh[i].sh_name, max_len) < max_len); \
      if (sh[i].sh_type & SHT_NOBITS) continue; \
      if (strcmp(shstrtab + sh[i].sh_name, ".strtab") == 0) \
        strtabidx = i; \
      if (strcmp(shstrtab + sh[i].sh_name, ".symtab") == 0) \
        symtabidx = i; \
    } \
    if (strtabidx && symtabidx) { \
      char* strtab = buf + sh[strtabidx].sh_offset; \
      sym_t* sym = (sym_t*)(buf + sh[symtabidx].sh_offset); \
      for (unsigned i = 0; i < sh[symtabidx].sh_size/sizeof(sym_t); i++) { \
        unsigned max_len = sh[strtabidx].sh_size - sym[i].st_name; \
        assert(sym[i].st_name < sh[strtabidx].  sh_size); \
        assert(strnlen(strtab + sym[i].st_name, max_len) < max_len); \
        symbols[strtab + sym[i].st_name] = sym[i].st_value; \
      } \
    } \
    } while(0)

  if (IS_ELF32(*eh64))
    LOAD_ELF(Elf32_Ehdr, Elf32_Phdr, Elf32_Shdr, Elf32_Sym);
  else
    LOAD_ELF(Elf64_Ehdr, Elf64_Phdr, Elf64_Shdr, Elf64_Sym);

  munmap(buf, size);
}

std::map<std::string, uint64_t> load_elf(const char* path, std::vector<uint8_t> *i_mem) {
    uint64_t MAX_MEM = 0xFFFFFF;
    char*  buffer;
    read_elf(path);

    long long int address, len;

    while(get_section(&address, &len)) {
        buffer = new char[len];
        for(unsigned int i = 0; i < len; i++) {
               buffer[i] = 0;
        }   
        read_section(address, buffer);
        uint32_t base_addr = address & MAX_MEM;

        if(base_addr > i_mem->size()) {
            i_mem->resize(address & MAX_MEM, 0);
            for(unsigned int i = 0; i < len; i++) {
               i_mem->push_back(buffer[i]);
            }
        }
        else {
            for(unsigned int i = 0; i < len; i++) {
               i_mem->push_back(buffer[i]);
            }
        }

        delete[] buffer;
    }

    /*
    printf("Printing Memory:\n");
    for(unsigned int i = 0; i < i_mem->size(); i++) {
        printf("Addr: %x Val: %x\n", i, (*i_mem)[i]);
    }
    */
    return symbols;
}

int dump_elf(const char* elf_file, const char* dump_file) {
    std::map<std::string, uint64_t> symbols;
    std::vector<uint8_t> mem;
    
    symbols = load_elf(elf_file, &mem);

    std::ofstream sigs(dump_file);

    const uint32_t incr = 4;
    sigs << std::setfill('0') << std::hex;
    for(uint64_t i = 0; i < mem.size(); i=i+incr) {
      for(uint64_t j = incr; j > 0; j--) {
        sigs << std::setw(2) << (uint16_t) mem[i+j-1];
      }
    
      sigs << std::endl;
    }

    sigs.close();    
    return 0;
}