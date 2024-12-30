/*
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 * Copyright (c) 2024 Chien Wong <m@xv97.com>
 */

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Compute the Internet Checksum, without the final one's complement.
 *
 * @param buf Buffer address. The address could be unaligned.
 * @param len Length of buffer
 *
 * @return Checksum of buffer
 */
uint16_t internet_checksum_fast(const void *buf, size_t len);

#ifdef __cplusplus
}
#endif
