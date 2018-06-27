cube: {
      2-----------3        +-----4-----+
     /'          /|       /'          /| 
    / '         / |     11 '         2 | 
   /  '        /  |     /  9        /  12 
  1-----------4   |    +-----1-----+   | 
  |   '       |   |    |   '       |   | 
  |   7 . . . | . 6    |   . . . 7 | . + 
  |  ,        |  /     6  ,        3  /  
  | ,         | /      | 8         | 5  
  |,          |/       |,          |/    
  8-----------5        +----10-----+
}

op_rubik: {void op_rubik(i8* a, i8* b) {
  // a //
  i8 *corn_p_a = a - 1;
  i8 *corn_o_a = corn_p_a + 8;
  i8 *edge_p_a = corn_p_a + 16;
  i8 *edge_o_a = corn_p_a + 28;
  // b //
  i8 *corn_p_b = b - 1;
  i8 *corn_o_b = corn_p_b + 8;
  i8 *edge_p_b = corn_p_b + 16;
  i8 *edge_o_b = corn_p_b + 28;

  int i, j;
  for (i = 1; i <= 8; i ++) {
    j = corn_p_a[i];
    corn_o_a[i] = 1 + (
      (corn_o_a[i] + corn_o_b[j] + 1) % 3
    );
    corn_p_a[i] = corn_p_b[j];
  }
  for (i = 1; i <= 12; i ++) {
    j = edge_p_a[i];
    edge_o_a[i] = 1 + (
      (edge_o_a[i] + edge_o_b[j]) % 2
    );
    edge_p_a[i] = edge_p_b[j];
  }
}}

op-rubik: make-native [
    a [vector!]
    b [vector!]
  ] {
  i8 *a = SER_DATA_RAW(VAL_SERIES(ARG(a)));
  i8 *b = SER_DATA_RAW(VAL_SERIES(ARG(b)));
  op_rubik(a, b);
  Move_Value(D_OUT, ARG(a));
  return R_OUT;
}

filter_rubik: {int filter_rubik(i8 *s, i8 *f, int threshold) {
  // s //
  i8 *corn_p_s = s - 1;
  i8 *corn_o_s = corn_p_s + 8;
  i8 *edge_p_s = corn_p_s + 16;
  i8 *edge_o_s = corn_p_s + 28;
  // b //
  i8 *corn_p_f = f - 1;
  i8 *corn_o_f = corn_p_f + 8;
  i8 *edge_p_f = corn_p_f + 16;
  i8 *edge_o_f = corn_p_f + 28;

  int i, v, t = 0;
  for (i = 1; i <= 8; i ++) {
    v = corn_p_f[i];
    if (v < 0 && (v + corn_p_s[i]) % 2) { 
      t++; if (t > threshold) break;
    }
    if (v > 0 && v != corn_p_s[i]) {
      t++; if (t > threshold) break;
    }
    v = corn_o_f[i];
    if (v && v != corn_o_s[i]) {
      t++; if (t > threshold) break;
    }
  }
  if (t <= threshold) 
    for (i = 1; i <= 12; i ++) {
      v = edge_p_f[i];
      if (v < 0 && (v + edge_p_s[i]) % 3) { 
        t++; if (t > threshold) break;
      }
      if (v > 0 && v != edge_p_s[i]) {
        t++; if (t > threshold) break;
      }
      v = edge_o_f[i];
      if (v && v != edge_o_s[i]) {
        t++; if (t > threshold) break;
      }
    }
  return t;
}}

filter-rubik: make-native [
    s [vector!] "status"
    f [vector!] "filter"
    threshold [integer!]
  ] {
  int threshold = VAL_INT32(ARG(threshold));
  i8 *s = SER_DATA_RAW(VAL_SERIES(ARG(s)));
  i8 *f = SER_DATA_RAW(VAL_SERIES(ARG(f)));
  int t = filter_rubik(s, f, threshold);
  Init_Integer(D_OUT, t);
  return R_OUT;
}

find_rubik: make-native [
    status [vector!]
    filter [vector!]
    threshold [integer!]
    seq [vector!]
    moves [vector!]
  ] {
  i8 *status = SER_DATA_RAW(VAL_SERIES(ARG(status)));
  i8 *filter = SER_DATA_RAW(VAL_SERIES(ARG(filter)));
  int threshold = VAL_INT32(ARG(threshold));
  i8 *seq = SER_DATA_RAW(VAL_SERIES(ARG(seq)));
  i8 *moves = SER_DATA_RAW(VAL_SERIES(ARG(moves)));
  i8 *m;
  int i, a, b, c, len = SER_LEN(VAL_SERIES(ARG(seq)));
  while (1) {
    for (i = 0; i < len; i ++) {
      if (seq[i] == 0) break;
    }
    if (i < len) {
      if (i == 0) seq[i] = 1;
      else if (seq[i-1] <= 3) seq[i] = 4;
      else if (seq[i-1] <= 6) seq[i] = 7;
      else seq[i] = 1;
      m = moves + 40 * (seq[i] - 1);
      op_rubik(status, m);
    }
    else {
      for (i = len - 1; i >= 0; i --) {
        c = seq[i];
        if (c < 18) {
          if (i > 0) {
            a = (seq[i-1] - 1) / 3;
            b = c / 3;
            if ((a == b) || (a % 2 && b == a - 1)) c = 3 * a + 3;
          }
        }
        if (c < 18) {c ++; break;}
        a = seq[i] - 1;
        if (a % 3 == 0) a +=2;
        else if (a % 3 == 2) a -= 2;
        m = moves + 40 * a;
        op_rubik(status, m);
        seq[i] = 0;
      }
      if (i < 0) break;
      a = seq[i] - 1;
      if (a % 3 == 0) a +=2;
      else if (a % 3 == 2) a -= 2;
      m = moves + 40 * a;
      op_rubik(status, m);
      m = moves + 40 * (c - 1);
      op_rubik(status, m);
      seq[i] = c;
    }
    if (i < 0) break;
    if (threshold >= filter_rubik(status, filter, threshold)) break;
  }
  Init_Integer(D_OUT, threshold);
  return R_OUT;
}

compile/options [
    op_rubik
    filter_rubik
    op-rubik
    filter-rubik
    find_rubik
  ][
  options "-nostdlib"
]

.: enfix tighten :op-rubik

make-rubik: function [
    spec [block!] {
      [corner-pos corner-or edge-pos edge-or]
      | [rubik1 rubik2 ...]
    }
  ][
  if not block? spec/1 [spec: reduce spec]
  if not block? spec/1 [fail ["invalid spec: " spec]]
  r: make vector! [integer! 8 40]
  j: 1
  for-next spec [
    for-each x spec/1 [r/:j: x j: me + 1]
  ]
  r
]

rubik: function [
    spec [block! | string!] {[rubik1 rubik2 ...]}
  ][
  if string? spec [
    ret: copy id
    parse spec [any
      [ "f"
        [ "2" (ret . f2)
        | "'" (ret . f')
        | (ret . f)
        ]
      | "b"
        [ "2" (ret . b2)
        | "'" (ret . b')
        | (ret . b)
        ]
      | "r"
        [ "2" (ret . r2)
        | "'" (ret . r')
        | (ret . r)
        ]
      | "l"
        [ "2" (ret . l2)
        | "'" (ret . l')
        | (ret . l)
        ]
      | "u"
        [ "2" (ret . u2)
        | "'" (ret . u')
        | (ret . u)
        ]
      | "d"
        [ "2" (ret . d2)
        | "'" (ret . d')
        | (ret . d)
        ]
    ]]
    return ret
  ]
  if not vector? spec/1 [spec: reduce spec]
  if not vector? spec/1 [fail ["invalid spec: " spec]]
  ret: copy id
  for-each x spec [ret . x]
  ret
]

id: make-rubik [ 
  [1 2 3 4 5 6 7 8]
  [1 1 1 1 1 1 1 1]
  [ 1  2  3  4  5  6  7  8  9 10 11 12]
  [ 1  1  1  1  1  1  1  1  1  1  1  1]
]
f: make-rubik [ 
  [4 2 3 5 8 6 7 1]
  [2 1 1 3 2 1 1 3]
  [ 3  2 10  4  5  1  7  8  9  6 11 12]
  [ 2  1  2  1  1  2  1  1  1  2  1  1]
]
b: make-rubik [
  [1 7 2 4 5 3 6 8]
  [1 3 2 1 1 3 2 1]
  [ 1  2  3  9  5  6 12  8  7 10 11  4]
  [ 1  1  1  2  1  1  2  1  2  1  1  2]
]
r: make-rubik [
  [1 2 6 3 4 5 7 8]
  [1 1 3 2 3 2 1 1]
  [ 1 12  2  4  3  6  7  8  9 10 11  5]
  [ 1  1  1  1  1  1  1  1  1  1  1  1]
]
l: make-rubik [
  [8 1 3 4 5 6 2 7]
  [3 2 1 1 1 1 3 2]
  [ 1  2  3  4  5  8  7  9 11 10  6 12]
  [ 1  1  1  1  1  1  1  1  1  1  1  1]
]
u: make-rubik [
  [2 3 4 1 5 6 7 8]
  [1 1 1 1 1 1 1 1]
  [11  1  3  2  5  6  7  8  9 10  4 12]
  [ 1  1  1  1  1  1  1  1  1  1  1  1]
]
d: make-rubik [
  [1 2 3 4 6 7 8 5]
  [1 1 1 1 1 1 1 1]
  [ 1  2  3  4  7  6  8 10  9  5 11 12]
  [ 1  1  1  1  1  1  1  1  1  1  1  1]
]

f2: rubik "ff"
b2: rubik "bb"
r2: rubik "rr"
l2: rubik "ll"
u2: rubik "uu"
d2: rubik "dd"

f': rubik "f2f"
b': rubik "b2b"
r': rubik "r2r"
l': rubik "l2l"
u': rubik "u2u"
d': rubik "d2d"

w-moves: [f f2 f' b b2 b' r r2 r' l l2 l' u u2 u' d d2 d']

moves: make vector! reduce ['integer! 8 18 * 40]
for-each m reduce w-moves [
  repeat i 40 [moves/1: m/:i moves: next moves]
]
moves: head moves

form-rubik: function [x] [
  s: make string! 100
  append s "corn_p: "
  append s form copy/part to-block x 8
  append s newline
  append s "corn_o: "
  append s form copy/part to-block at x 9 8
  append s newline
  append s "edge_p: "
  append s form copy/part to-block at x 17 12
  append s newline
  append s "edge_o: "
  append s form copy/part to-block at x 29 12
  append s newline
]

;;; MAIN ;;;
args: system/options/args
filter: make-rubik [ 
  [-1 -2 -3 -4 -5 -6 -7 -8]
  [1 1 1 1 1 1 1 1]
  [0 0 0 0 0 0 0 0 0 0 0 0]
  [1 1 1 1 1 1 1 1 1 1 1 1]
]
score: make-rubik [ 
  [0 0 0 0 0 0 0 0]
  [0 0 0 0 0 0 0 0]
  [-1 -2 -3 -1 -2 -3 -1 -2 -3 -1 -2 -3]
  [ 0  0  0  0  0  0  0  0  0  0  0  0]
]
seq: make vector! reduce ['integer! 8 to-integer args/1]
status: copy id
print delta-time [
forever [
  find_rubik status filter 0 seq moves
  if seq/1 = 0 [break]
  t: filter-rubik status score 2
  if any [t = 0 t > 2] [continue]
  s: copy ""
  for-next seq [
    if 0 = seq/1 [break]
    append s w-moves/(seq/1)
    append s space
  ]
  if s = "" [break]
  print s
]
]
quit


;; vim: set sw=2 ts=2 sts=2:
