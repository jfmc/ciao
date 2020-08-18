/*
 *  atomic_basic.c
 *
 *  See Copyright Notice in ciaoengine.pl
 */

#include <ciao/eng.h>
#if !defined(OPTIM_COMP)
#include <ciao/eng_bignum.h> /* for StringToInt,StringToInt_nogc */
#include <ciao/eng_gc.h> /* for StringToInt,StringToInt_nogc */
#include <ciao/eng_registry.h>
#include <ciao/dtoa_ryu.h>
#include <ciao/runtime_control.h> /* push_choicept,pop_choicept */
#include <ciao/io_basic.h> /* isValidRune */
#include <ciao/atomic_basic.h>
#endif

#include <stdlib.h> /* atof() */
#include <string.h>
#include <math.h> /* NAN, INFINITY */

static CBOOL__PROTO(prolog_constant_codes,
                    bool_t atomp,
                    bool_t numberp,
                    int ci);

CBOOL__PROTO(prolog_name) {
  // ERR__FUNCTOR("atomic_basic:name", 2);
  CBOOL__LASTCALL(prolog_constant_codes,TRUE,TRUE,1);
}

CBOOL__PROTO(prolog_atom_codes) {
  // ERR__FUNCTOR("atomic_basic:atom_codes", 2);
  CBOOL__LASTCALL(prolog_constant_codes,TRUE,FALSE,1);
}

CBOOL__PROTO(prolog_number_codes_2) {
  // ERR__FUNCTOR("atomic_basic:number_codes", 2);
  CBOOL__LASTCALL(prolog_constant_codes,FALSE,TRUE,1);
}

CBOOL__PROTO(prolog_number_codes_3) {
  // ERR__FUNCTOR("atomic_basic:number_codes", 3);
  CBOOL__LASTCALL(prolog_constant_codes,FALSE,TRUE,2);
}

static inline bool_t is_digit10(char c) {
  return c >= '0' && c <= '9';
}

static inline bool_t str_to_flt64(char *AtBuf, int base, flt64_t *rnum) {
  char *s = AtBuf;

  if (base != 10) return FALSE;

  /* first pass to check syntax */
  char c;
  c = *s++;
  /* skip sign */
  if (c=='-') c = *s++;
  /* skip AAA in AAA.BBB */
  while(is_digit10(c)) { c = *s++; };
  /* skip '.' */
  if (c!='.') return FALSE;
  c = *s++;
  /* skip BBB in AAA.BBB */
  if (!is_digit10(c)) return FALSE;
  c = *s++;
  while(is_digit10(c)) { c = *s++; };
  /* skip exponent */
  if (c=='e' || c=='E') {
    c = *s++;
    if (c=='+' || c=='-') c = *s++;
    if (!is_digit10(c)) return FALSE;
    c = *s++;
    while(is_digit10(c)) { c = *s++; };
  }
  if (c!='\0') return FALSE;
  /* convert, asumming no errors */ 
  *rnum = atof(AtBuf);
  return TRUE;
}

 /* INTEGER :== [minus]{digit} */
 /* FLOAT :== [minus]{digit}.{digit}[exp[sign]{digit}] */
 /* ATOM :== {char} */

/* string_to_number() tries to convert the string pointed to by AtBuf in a
   number contained in the tagged word *strnum.  If this cannot be done
   (e.g., AtBuf does not correspond syntactically to a number), FALSE is
   returned.  Otherwise, TRUE is returned and the conversion is done */

CBOOL__PROTO(string_to_number,
             char *AtBuf,
             int base,
             tagged_t *strnum,
             int arity) {
  static const char char_digit[] = {
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1, /* 0-9 */
    -1,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24, /* A... */
    25,26,27,28,29,30,31,32,33,34,35,-1,-1,-1,-1,-1, /* ...Z */
    -1,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24, /* a... */
    25,26,27,28,29,30,31,32,33,34,35,-1,-1,-1,-1,-1, /* ...z */
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  };

  bool_t sign = FALSE;
  char *s = AtBuf;
  int i, d;
  i = *s++;
  if (i=='-') {
    sign = TRUE;
    i = *s++;
  }
  /* special cases: nan and infinity */
  if (i=='0') {
    if (strcmp(s, ".Nan")==0) {
      double num = sign ? -NAN : NAN;
      *strnum = MakeFloat(Arg, num);
      CBOOL__PROCEED;
    } else if (strcmp(s, ".Inf")==0) {
      double num = sign ? -INFINITY : INFINITY;
      *strnum = MakeFloat(Arg, num);
      CBOOL__PROCEED;
    }
  }
  /* integers or float */
  d = char_digit[i];
  while (0 <= d && d < base) {
    i = *s++;
    d = char_digit[i];
  }
  if ((s - AtBuf) - sign <= 1) {    
    return FALSE; /* No digit found! */
  }
  if (i=='\0') { /* ended in \0, integer (small or bignum) */
    StringToInt(AtBuf, base, *strnum, arity);
    return TRUE;
  } else if (i=='.') { /* maybe a float */ /* TODO: allow 1e0 syntax (see tokenize.pl too) */
    flt64_t num;
    if (str_to_flt64(AtBuf, base, &num)) {
      *strnum = MakeFloat(Arg, num);
      return TRUE;
    } else {
      return FALSE;
    }
  }
  /* maybe a non-numeric atom */
  return FALSE;
}

/* Precond: 2<=abs(base)<=36 for integers, base==10 for floats */
CVOID__PROTO(number_to_string, tagged_t term, int base) {
  if (TaggedIsSmall(term)) {
    intmach_t l = GetSmall(term);
    char hibase = 'a'-10;
    bool_t sx = (l>=0);
    intmach_t digit;
    char *c0, *c, d;

    if (base<0) {
      hibase = 'A'-10;
      base = -base;
    }
    c = Atom_Buffer;
    if (!sx) {
      *c++ = '-';
      l = -l;
    }

    do {
      digit = l % base;
      l /= base;
      *c++ = (digit<10 ? '0'+digit : hibase+digit);
    } while (l>0);

    *c++ = 0;
    for (c0=Atom_Buffer+1-sx, c-=2; c0<c; c0++, c--) {
      d = *c0;
      *c0 = *c;
      *c = d;
    }
  } else if (IsFloat(term)) {
    union {
      flt64_t i;
      tagged_t p[sizeof(flt64_t)/sizeof(tagged_t)];
    } u;
    char *cbuf;

    /* f = GetFloat(term); */
#if LOG2_bignum_size == 5
    u.p[0] = *TagToArg(term,1);
    u.p[1] = *TagToArg(term,2);
#elif LOG2_bignum_size == 6
    u.p[0] = *TagToArg(term,1);
#endif

    /* if (1024 > Atom_Buffer_Length) EXPAND_ATOM_BUFFER(102400); */
    cbuf = Atom_Buffer;
    dtoa_ryu(u.i, cbuf); /* assume base==10 */
  } else {
    bn_to_string(Arg,(bignum_t *)TagToSTR(term),base);
  }
}

/*

  Note: The ci parameter indicates where are the String argument.  If
  ci = 2, then there are 3 parameters, indicating that the second
  parameter could be the numeric base.

 */
static CBOOL__PROTO(prolog_constant_codes, 
                    bool_t atomp,
                    bool_t numberp,
                    int ci)
{
  /* Note: This ERR__FUNCTOR is not related to an exported predicate,
     since prolog_constant_codes is called from other places. I have
     some ideas of refining error reporting without hindering
     performance (please, ask me before changing this code). -- JFMC
   */
  ERR__FUNCTOR("atomic_basic:$constant_codes", 3);
  char *s;
  int i, base;
  c_rune_t rune;
  tagged_t car, cdr;

  DEREF(X(0),X(0));
  DEREF(X(1),X(1));
  if (ci==2) DEREF(X(2),X(2));

  /* Construct a character string from the input list */
  cdr = X(ci);
  s = Atom_Buffer;
  for (i=0; cdr!=atom_nil; i++) {
    if (IsVar(cdr)) {
      goto construct_list;
    } else if (!TagIsLST(cdr)) {
      BUILTIN_ERROR(TYPE_ERROR(LIST),X(ci),ci+1);
    } else if (i == Atom_Buffer_Length){
      EXPAND_ATOM_BUFFER(Atom_Buffer_Length*2);
      s = Atom_Buffer+i;
    }
    DerefCar(car,cdr);
    if (IsVar(car)) {
      goto construct_list;
    }
    if (!TaggedIsSmall(car)) {
      if (TagIsLarge(car) && !LargeIsFloat(car)) {
        BUILTIN_ERROR(REPRESENTATION_ERROR(CHARACTER_CODE), car ,ci+1);
      }
      BUILTIN_ERROR(TYPE_ERROR(INTEGER), car, ci+1);
    }
    rune = GetSmall(car);
    if (!isValidRune(rune)) {
      BUILTIN_ERROR(REPRESENTATION_ERROR(CHARACTER_CODE), car, ci+1);
    }
    *(s++) = rune;
    DerefCdr(cdr,cdr);
  }
  if (i == Atom_Buffer_Length) {
    EXPAND_ATOM_BUFFER(Atom_Buffer_Length*2);
    s = Atom_Buffer+i;
  }
  *s++ = '\0';

  /* s contains now the string of character codes, and i its size */

#if !defined(USE_DYNAMIC_ATOM_SIZE)
  if (i>=MAXATOM) {
    BUILTIN_ERROR(REPRESENTATION_ERROR(MAX_ATOM_LENGTH), X(0), 1);
  }
#endif

  if(!IsVar(X(0))){
    if (!numberp) {
      if(!TaggedIsATM(X(0))) {
        BUILTIN_ERROR(TYPE_ERROR(STRICT_ATOM), X(0), 1);
      }
    } else if (!atomp) {
      if (!IsNumber(X(0))) {
        BUILTIN_ERROR(TYPE_ERROR(NUMBER), X(0), 1);
      }
    } else {
      if (!IsAtomic(X(0))) {
        BUILTIN_ERROR(TYPE_ERROR(ATOMIC),X(0),1);
      }
    }
  }
  
  if (numberp) {
    tagged_t result;
    if (ci==2) {
      if (TaggedIsSmall(X(1))) {
        base = GetSmall(X(1));
      } else if ((TagIsLarge(X(1)) && !LargeIsFloat(X(1)))) {
        base = 0;  // forces SOURCE_SINK error
      } else {
        BUILTIN_ERROR(TYPE_ERROR(INTEGER),X(1),2);
      }
    } else { // if (ci==1)
      base = GetSmall(current_radix);
    }
    if ((base < 2)||(base > 36)) {
      //printf("--9--\n");
      BUILTIN_ERROR(DOMAIN_ERROR(SOURCE_SINK),X(1),2);
    }
    if (string_to_number(Arg, Atom_Buffer, base, &result, ci+1)) {
      return cunify(Arg, result, X(0));
    }
  }
  return atomp && cunify(Arg,init_atom_check(Atom_Buffer),X(0));

 construct_list:
  if (IsVar(X(0))) {
    BUILTIN_ERROR(INSTANTIATION_ERROR,X(0),2);
  }

  if (numberp && IsNumber(X(0))) {
    if (ci==2) {
      if (TaggedIsSmall(X(1))) {
        base = GetSmall(X(1));
      } else if (TagIsLarge(X(1)) && !LargeIsFloat(X(1))) {
        base = 0; // forces SOURCE_SINK error
      } else {
        BUILTIN_ERROR(TYPE_ERROR(INTEGER),X(1),2);
      }
    } else { // if (ci==1)
      base = GetSmall(current_radix);
    }
    if ((base < 2)||(base > 36)||
        (base != 10 && IsFloat(X(0)))) {
      BUILTIN_ERROR(DOMAIN_ERROR(SOURCE_SINK),X(1),2);
    }
    number_to_string(Arg,X(0),base);
    s = Atom_Buffer;
  } else if (atomp && TaggedIsATM(X(0))) {
    s = GetString(X(0));
  } else {
    if (numberp) {
      if (atomp) {
        BUILTIN_ERROR(TYPE_ERROR(ATOMIC),X(0),1);
      } else {
        BUILTIN_ERROR(TYPE_ERROR(NUMBER),X(0),1);
      }
    } else {
      BUILTIN_ERROR(TYPE_ERROR(STRICT_ATOM),X(0),1);
    }
  }

  i = strlen(s);
  s += i;

  ENSURE_HEAP_LST(i, ci+1);
  cdr = atom_nil;
  while (i>0) {
    i--;
    s--;
    MakeLST(cdr,MakeSmall(*((unsigned char *)s)),cdr);
  }
  return cunify(Arg,cdr,X(ci));
}

CBOOL__PROTO(prolog_atom_length) {
  ERR__FUNCTOR("atomic_basic:atom_length", 2);
  DEREF(X(0),X(0));
  DEREF(X(1),X(1));

  if (!TaggedIsATM(X(0)))
    ERROR_IN_ARG(X(0),1,STRICT_ATOM);

  if (!IsInteger(X(1)) && !IsVar(X(1))) {
    BUILTIN_ERROR(TYPE_ERROR(INTEGER),X(1),2);
  }

#if defined(USE_ATOM_LEN)
  return cunify(Arg,MakeSmall(GetAtomLen(X(0))),X(1));
#else
  return cunify(Arg,MakeSmall(strlen(GetString(X(0)))),X(1));
#endif
}

/* sub_atom(Atom, Before, Lenght, Sub_atom) */
CBOOL__PROTO(prolog_sub_atom)
{
  ERR__FUNCTOR("atomic_basic:sub_atom", 4);
  char *s, *s1;
  int l, b, atom_length;

  DEREF(X(0),X(0));
  DEREF(X(1),X(1));
  DEREF(X(2),X(2));
  DEREF(X(3),X(3));

  if (!TaggedIsATM(X(0)))
    ERROR_IN_ARG(X(0),1,STRICT_ATOM);
  if (!IsInteger(X(1)))
    ERROR_IN_ARG(X(1),2,INTEGER);
  if (!IsInteger(X(2)))
    ERROR_IN_ARG(X(2),3,INTEGER);

  s = GetString(X(0));
#if defined(USE_ATOM_LEN)
  l = GetAtomLen(X(0));
#else
  l = strlen(s);
#endif

  b = GetInteger(X(1));
  if (b < 0 || b > l)
    return FALSE;

  atom_length = GetInteger(X(2));
  if (atom_length < 0 || atom_length+b > l)
    return FALSE;

  s += b;

  if (Atom_Buffer_Length <= atom_length)
    EXPAND_ATOM_BUFFER(atom_length+1);

  s1 = Atom_Buffer;

  strncpy(s1, s, atom_length);

  *(s1+atom_length) = '\0';

  return cunify(Arg,init_atom_check(Atom_Buffer),X(3));

}

CBOOL__PROTO(nd_atom_concat);

CBOOL__PROTO(prolog_atom_concat)
{
  ERR__FUNCTOR("atomic_basic:atom_concat", 3);
  int new_atom_length;
  char *s, *s1, *s2;

  DEREF(X(0),X(0));
  DEREF(X(1),X(1));
  DEREF(X(2),X(2));

  if (TaggedIsATM(X(0))) {
    s1 = GetString(X(0));

    if (TaggedIsATM(X(1))) {
      if (!TaggedIsATM(X(2)) && !IsVar(X(2))) {
        BUILTIN_ERROR(TYPE_ERROR(STRICT_ATOM),X(2),3);
      }
/* atom_concat(+, +, ?) */
      s2 = GetString(X(1));

#if defined(USE_ATOM_LEN)
      new_atom_length = GetAtomLen(X(0)) + GetAtomLen(X(1)) + 1;
#else
      new_atom_length = strlen(s1) + strlen(s2) + 1;
#endif

#if defined(USE_DYNAMIC_ATOM_SIZE)
      if (new_atom_length >= Atom_Buffer_Length) {
        EXPAND_ATOM_BUFFER(new_atom_length);
      }
#else
      if (new_atom_length > MAXATOM) {
        BUILTIN_ERROR(REPRESENTATION_ERROR(MAX_ATOM_LENGTH), X(2), 3);
      }
#endif

      /* Append the two strings in atom_buffer */
      s = Atom_Buffer;
      while (*s1)
        *s++ = *s1++;
      while (*s2)
        *s++ = *s2++;
      *s = '\0';
      return cunify(Arg,init_atom_check(Atom_Buffer),X(2));
    } else if (IsVar(X(1))) {
      if (!TaggedIsATM(X(2))) { ERROR_IN_ARG(X(2),3,STRICT_ATOM); }
      /* atom_concat(+, -, +) */
      s2 = GetString(X(2));

#if defined(USE_ATOM_LEN)
      new_atom_length = GetAtomLen(X(2))+1;
#else
      new_atom_length = strlen(s2) + 1;
#endif
      if (new_atom_length >= Atom_Buffer_Length)
          EXPAND_ATOM_BUFFER(new_atom_length);

      for ( ; *s1 && *s2 ; s1++, s2++)
        if (*s1 != *s2) return FALSE;

      if (*s1) return FALSE;

      s = Atom_Buffer;

      strcpy(s, s2);

      return cunify(Arg,init_atom_check(Atom_Buffer),X(1));
    } else {
      BUILTIN_ERROR(TYPE_ERROR(STRICT_ATOM),X(1),2);
    }
  } else if (IsVar(X(0))) {
    if (!TaggedIsATM(X(2)))
        { ERROR_IN_ARG(X(2),3,STRICT_ATOM); }

    if (TaggedIsATM(X(1))) {
/* atom_concat(-, +, +) */

      s1 = GetString(X(1));
      s2 = GetString(X(2));

#if defined(USE_ATOM_LEN)
      if ((new_atom_length = (GetAtomLen(X(2)) - GetAtomLen(X(1)))) < 0)
        return FALSE;
#else
      if ((new_atom_length = strlen(s2)-strlen(s1)) < 0)
        return FALSE;
#endif

      if (new_atom_length >= Atom_Buffer_Length) 
        EXPAND_ATOM_BUFFER(new_atom_length+1);

      s = s2+new_atom_length;

      if (strcmp(s1, s)) /* different */
        return FALSE;

      s = Atom_Buffer;

      strncpy(s, s2, new_atom_length);

      *(s+new_atom_length) = '\0';

      return cunify(Arg,init_atom_check(Atom_Buffer),X(0));
    } else if (IsVar(X(1))) {
/* atom_concat(-, -, +) */

      s2 = GetString(X(2));
#if defined(USE_ATOM_LEN)
      new_atom_length = GetAtomLen(X(2))+1;
#else
      new_atom_length = strlen(s2)+1;
#endif
      if (new_atom_length >= Atom_Buffer_Length)
        EXPAND_ATOM_BUFFER(new_atom_length);
      X(3) = TaggedZero;
      push_choicept(Arg,address_nd_atom_concat);
      return nd_atom_concat(Arg);
    } else {
      BUILTIN_ERROR(TYPE_ERROR(STRICT_ATOM),X(1),2);
    }
  } else {
    BUILTIN_ERROR(TYPE_ERROR(STRICT_ATOM),X(0),1);
  }
}

/* Nondet support for atom_concat/3 */
CBOOL__PROTO(nd_atom_concat) {
  intmach_t i = GetSmall(X(3));
  char *s, *s1, *s2;

  w->node->term[3] += MakeSmallDiff(1);

  s2 = GetString(X(2));

  s = Atom_Buffer;

  s1 = s2 + i;
  strcpy(s, s1);
  CBOOL__UnifyCons(init_atom_check(Atom_Buffer),X(1));

  strcpy(s, s2);
  *(s+i) = '\0';
  CBOOL__UnifyCons(init_atom_check(Atom_Buffer),X(0));

  if (i == strlen(s2))
    pop_choicept(Arg);
  
  return TRUE;
}

