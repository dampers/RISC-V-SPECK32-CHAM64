# SPECK32 and CHAM64 on 32-bit RISC-V

#### [CISC-S'24] Optimized Parallel Implementation of ARX-based Lightweight Block Cipher SPECK32 and CHAM64 on 32-bit RISC-V architectures

### Double block test vector for SPECK32
##### plaintext   = 0x6574694C 0x6574694C
##### master key  = 0x0100 0x0908 0x1110 0x1918
##### ciphertext  = 0xA86842F2 0xA86842F2

### Double block test vector for CHAM64
##### plaintext   = 0x33221100 0x77665544 0x33221100 0x77665544
##### master key  = 0x0100 0x0302 0x0504 0x0706 0x0908 0x0B0A 0x0D0C 0x0F0E
##### ciphertext  = 0x12046579 0xE5A9123F 0x12046579 0xE5A9123F


This code encrypts after pre-computing the key schedule of SPECK32 and CHAM64


### Abstract
SPECK and CHAM, lightweight block ciphers based on ARX, have been proposed as requirements for secure communication channels in low-end embedded device environments. RISC-V is an open source instruction set and has attracted a lot of attention as an ISA that can be used by anyone at no additional cost. In this paper, we present an optimized parallel implementation of two-block encryption for SPECK32 and CHAM64 on 32-bit RISC-V architecture. The results of the proposed technique show a 66.8% improvement in performance in terms of clock cycles per byte over the existing parallel implementation techniques for CHAM64, and a 62.7% improvement over the reference implementation for SPECK32. In particular, the modular addition parallelisation technique proposed in this paper is expected to perform well in parallel implementations of other ARX-based ciphers or in parallel implementations on embedded architectures that do not support vector operations.

