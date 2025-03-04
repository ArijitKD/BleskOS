//BleskOS

/*
* MIT License
* Copyright (c) 2023-2025 Vendelín Slezák
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

static inline void outb(word_t port, byte_t value) {
 asm volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline void outw(word_t port, word_t value) {
 asm volatile ("outw %0, %1" : : "a"(value), "Nd"(port));
}

static inline void outd(word_t port, dword_t value) {
 asm volatile ("outl %0, %1" : : "a"(value), "Nd"(port));
}

static inline byte_t inb(word_t port) {
 byte_t value;
 asm volatile ("inb %1, %0" : "=a"(value) : "Nd"(port));
 return value;
}

static inline word_t inw(word_t port) {
 word_t value;
 asm volatile ("inw %1, %0" : "=a"(value) : "Nd"(port));
 return value;
}

static inline dword_t ind(word_t port) {
 dword_t value;
 asm volatile ("inl %1, %0" : "=a"(value) : "Nd"(port));
 return value;
}

void mmio_outb(dword_t base, byte_t value) {
 volatile byte_t *mem = (byte_t *) (base);
 *mem = value;
}

void mmio_outw(dword_t base, word_t value) {
 volatile word_t *mem = (word_t *) (base);
 *mem = value;
}

void mmio_outd(dword_t base, dword_t value) {
 volatile dword_t *mem = (dword_t *) (base);
 *mem = value;
}

byte_t mmio_inb(dword_t base) {
 volatile byte_t *mem = (byte_t *) (base);
 return *mem;
}

word_t mmio_inw(dword_t base) {
 volatile word_t *mem = (word_t *) (base);
 return *mem;
}

dword_t mmio_ind(dword_t base) {
 volatile dword_t *mem = (dword_t *) (base);
 return *mem;
}