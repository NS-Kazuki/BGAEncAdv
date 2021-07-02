module iconv.iconv;
/* Copyright (C) 1997, 1998, 1999, 2000, 2003 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

/* Identifier for conversion method from one codeset to another.  */
alias void* iconv_t;

extern (C):

/* Allocate descriptor for code conversion from codeset FROMCODE to
   codeset TOCODE.

   This function is a possible cancellation points and therefore not
   marked with __THROW.  */
iconv_t iconv_open (in char* __tocode, in char* __fromcode);

/* Convert at most *INBYTESLEFT bytes from *INBUF according to the
   code conversion algorithm specified by CD and place up to
   *OUTBYTESLEFT bytes in buffer at *OUTBUF.  */
size_t iconv (iconv_t __cd, in char** __inbuf,
		      in size_t* __inbytesleft,
		      char**  __outbuf,
		      size_t* __outbytesleft);

/* Free resources allocated for descriptor CD for code conversion.

   This function is a possible cancellation points and therefore not
   marked with __THROW.  */
int iconv_close (iconv_t __cd);

/* iconv.h */
