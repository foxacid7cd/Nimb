# 1 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/src/nvim/math.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 400 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/src/nvim/math.c" 2




# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/cdefs.h" 1 3 4
# 666 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/cdefs.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_symbol_aliasing.h" 1 3 4
# 667 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/cdefs.h" 2 3 4
# 732 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/cdefs.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_posix_availability.h" 1 3 4
# 733 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/cdefs.h" 2 3 4
# 31 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/Availability.h" 1 3 4
# 165 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/Availability.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/AvailabilityVersions.h" 1 3 4
# 166 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/Availability.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/AvailabilityInternal.h" 1 3 4
# 167 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/Availability.h" 2 3 4
# 32 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 2 3 4
# 44 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
    typedef float float_t;
    typedef double double_t;
# 111 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
extern int __math_errhandling(void);
# 131 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
extern int __fpclassifyf(float);
extern int __fpclassifyd(double);
extern int __fpclassifyl(long double);
# 174 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
inline __attribute__ ((__always_inline__)) int __inline_isfinitef(float);
inline __attribute__ ((__always_inline__)) int __inline_isfinited(double);
inline __attribute__ ((__always_inline__)) int __inline_isfinitel(long double);
inline __attribute__ ((__always_inline__)) int __inline_isinff(float);
inline __attribute__ ((__always_inline__)) int __inline_isinfd(double);
inline __attribute__ ((__always_inline__)) int __inline_isinfl(long double);
inline __attribute__ ((__always_inline__)) int __inline_isnanf(float);
inline __attribute__ ((__always_inline__)) int __inline_isnand(double);
inline __attribute__ ((__always_inline__)) int __inline_isnanl(long double);
inline __attribute__ ((__always_inline__)) int __inline_isnormalf(float);
inline __attribute__ ((__always_inline__)) int __inline_isnormald(double);
inline __attribute__ ((__always_inline__)) int __inline_isnormall(long double);
inline __attribute__ ((__always_inline__)) int __inline_signbitf(float);
inline __attribute__ ((__always_inline__)) int __inline_signbitd(double);
inline __attribute__ ((__always_inline__)) int __inline_signbitl(long double);

inline __attribute__ ((__always_inline__)) int __inline_isfinitef(float __x) {
    return __x == __x && __builtin_fabsf(__x) != __builtin_inff();
}
inline __attribute__ ((__always_inline__)) int __inline_isfinited(double __x) {
    return __x == __x && __builtin_fabs(__x) != __builtin_inf();
}
inline __attribute__ ((__always_inline__)) int __inline_isfinitel(long double __x) {
    return __x == __x && __builtin_fabsl(__x) != __builtin_infl();
}
inline __attribute__ ((__always_inline__)) int __inline_isinff(float __x) {
    return __builtin_fabsf(__x) == __builtin_inff();
}
inline __attribute__ ((__always_inline__)) int __inline_isinfd(double __x) {
    return __builtin_fabs(__x) == __builtin_inf();
}
inline __attribute__ ((__always_inline__)) int __inline_isinfl(long double __x) {
    return __builtin_fabsl(__x) == __builtin_infl();
}
inline __attribute__ ((__always_inline__)) int __inline_isnanf(float __x) {
    return __x != __x;
}
inline __attribute__ ((__always_inline__)) int __inline_isnand(double __x) {
    return __x != __x;
}
inline __attribute__ ((__always_inline__)) int __inline_isnanl(long double __x) {
    return __x != __x;
}
inline __attribute__ ((__always_inline__)) int __inline_signbitf(float __x) {
    union { float __f; unsigned int __u; } __u;
    __u.__f = __x;
    return (int)(__u.__u >> 31);
}
inline __attribute__ ((__always_inline__)) int __inline_signbitd(double __x) {
    union { double __f; unsigned long long __u; } __u;
    __u.__f = __x;
    return (int)(__u.__u >> 63);
}
# 237 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
inline __attribute__ ((__always_inline__)) int __inline_signbitl(long double __x) {
    union { long double __f; unsigned long long __u;} __u;
    __u.__f = __x;
    return (int)(__u.__u >> 63);
}

inline __attribute__ ((__always_inline__)) int __inline_isnormalf(float __x) {
    return __inline_isfinitef(__x) && __builtin_fabsf(__x) >= 1.17549435e-38F;
}
inline __attribute__ ((__always_inline__)) int __inline_isnormald(double __x) {
    return __inline_isfinited(__x) && __builtin_fabs(__x) >= 2.2250738585072014e-308;
}
inline __attribute__ ((__always_inline__)) int __inline_isnormall(long double __x) {
    return __inline_isfinitel(__x) && __builtin_fabsl(__x) >= 2.2250738585072014e-308L;
}
# 308 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
extern float acosf(float);
extern double acos(double);
extern long double acosl(long double);

extern float asinf(float);
extern double asin(double);
extern long double asinl(long double);

extern float atanf(float);
extern double atan(double);
extern long double atanl(long double);

extern float atan2f(float, float);
extern double atan2(double, double);
extern long double atan2l(long double, long double);

extern float cosf(float);
extern double cos(double);
extern long double cosl(long double);

extern float sinf(float);
extern double sin(double);
extern long double sinl(long double);

extern float tanf(float);
extern double tan(double);
extern long double tanl(long double);

extern float acoshf(float);
extern double acosh(double);
extern long double acoshl(long double);

extern float asinhf(float);
extern double asinh(double);
extern long double asinhl(long double);

extern float atanhf(float);
extern double atanh(double);
extern long double atanhl(long double);

extern float coshf(float);
extern double cosh(double);
extern long double coshl(long double);

extern float sinhf(float);
extern double sinh(double);
extern long double sinhl(long double);

extern float tanhf(float);
extern double tanh(double);
extern long double tanhl(long double);

extern float expf(float);
extern double exp(double);
extern long double expl(long double);

extern float exp2f(float);
extern double exp2(double);
extern long double exp2l(long double);

extern float expm1f(float);
extern double expm1(double);
extern long double expm1l(long double);

extern float logf(float);
extern double log(double);
extern long double logl(long double);

extern float log10f(float);
extern double log10(double);
extern long double log10l(long double);

extern float log2f(float);
extern double log2(double);
extern long double log2l(long double);

extern float log1pf(float);
extern double log1p(double);
extern long double log1pl(long double);

extern float logbf(float);
extern double logb(double);
extern long double logbl(long double);

extern float modff(float, float *);
extern double modf(double, double *);
extern long double modfl(long double, long double *);

extern float ldexpf(float, int);
extern double ldexp(double, int);
extern long double ldexpl(long double, int);

extern float frexpf(float, int *);
extern double frexp(double, int *);
extern long double frexpl(long double, int *);

extern int ilogbf(float);
extern int ilogb(double);
extern int ilogbl(long double);

extern float scalbnf(float, int);
extern double scalbn(double, int);
extern long double scalbnl(long double, int);

extern float scalblnf(float, long int);
extern double scalbln(double, long int);
extern long double scalblnl(long double, long int);

extern float fabsf(float);
extern double fabs(double);
extern long double fabsl(long double);

extern float cbrtf(float);
extern double cbrt(double);
extern long double cbrtl(long double);

extern float hypotf(float, float);
extern double hypot(double, double);
extern long double hypotl(long double, long double);

extern float powf(float, float);
extern double pow(double, double);
extern long double powl(long double, long double);

extern float sqrtf(float);
extern double sqrt(double);
extern long double sqrtl(long double);

extern float erff(float);
extern double erf(double);
extern long double erfl(long double);

extern float erfcf(float);
extern double erfc(double);
extern long double erfcl(long double);




extern float lgammaf(float);
extern double lgamma(double);
extern long double lgammal(long double);

extern float tgammaf(float);
extern double tgamma(double);
extern long double tgammal(long double);

extern float ceilf(float);
extern double ceil(double);
extern long double ceill(long double);

extern float floorf(float);
extern double floor(double);
extern long double floorl(long double);

extern float nearbyintf(float);
extern double nearbyint(double);
extern long double nearbyintl(long double);

extern float rintf(float);
extern double rint(double);
extern long double rintl(long double);

extern long int lrintf(float);
extern long int lrint(double);
extern long int lrintl(long double);

extern float roundf(float);
extern double round(double);
extern long double roundl(long double);

extern long int lroundf(float);
extern long int lround(double);
extern long int lroundl(long double);




extern long long int llrintf(float);
extern long long int llrint(double);
extern long long int llrintl(long double);

extern long long int llroundf(float);
extern long long int llround(double);
extern long long int llroundl(long double);


extern float truncf(float);
extern double trunc(double);
extern long double truncl(long double);

extern float fmodf(float, float);
extern double fmod(double, double);
extern long double fmodl(long double, long double);

extern float remainderf(float, float);
extern double remainder(double, double);
extern long double remainderl(long double, long double);

extern float remquof(float, float, int *);
extern double remquo(double, double, int *);
extern long double remquol(long double, long double, int *);

extern float copysignf(float, float);
extern double copysign(double, double);
extern long double copysignl(long double, long double);

extern float nanf(const char *);
extern double nan(const char *);
extern long double nanl(const char *);

extern float nextafterf(float, float);
extern double nextafter(double, double);
extern long double nextafterl(long double, long double);

extern double nexttoward(double, long double);
extern float nexttowardf(float, long double);
extern long double nexttowardl(long double, long double);

extern float fdimf(float, float);
extern double fdim(double, double);
extern long double fdiml(long double, long double);

extern float fmaxf(float, float);
extern double fmax(double, double);
extern long double fmaxl(long double, long double);

extern float fminf(float, float);
extern double fmin(double, double);
extern long double fminl(long double, long double);

extern float fmaf(float, float, float);
extern double fma(double, double, double);
extern long double fmal(long double, long double, long double);
# 588 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
extern float __exp10f(float) __attribute__((availability(macos,introduced=10.9))) __attribute__((availability(ios,introduced=7.0)));
extern double __exp10(double) __attribute__((availability(macos,introduced=10.9))) __attribute__((availability(ios,introduced=7.0)));





inline __attribute__ ((__always_inline__)) void __sincosf(float __x, float *__sinp, float *__cosp);
inline __attribute__ ((__always_inline__)) void __sincos(double __x, double *__sinp, double *__cosp);
# 605 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
extern float __cospif(float) __attribute__((availability(macos,introduced=10.9))) __attribute__((availability(ios,introduced=7.0)));
extern double __cospi(double) __attribute__((availability(macos,introduced=10.9))) __attribute__((availability(ios,introduced=7.0)));
extern float __sinpif(float) __attribute__((availability(macos,introduced=10.9))) __attribute__((availability(ios,introduced=7.0)));
extern double __sinpi(double) __attribute__((availability(macos,introduced=10.9))) __attribute__((availability(ios,introduced=7.0)));
extern float __tanpif(float) __attribute__((availability(macos,introduced=10.9))) __attribute__((availability(ios,introduced=7.0)));
extern double __tanpi(double) __attribute__((availability(macos,introduced=10.9))) __attribute__((availability(ios,introduced=7.0)));
# 636 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
inline __attribute__ ((__always_inline__)) void __sincospif(float __x, float *__sinp, float *__cosp);
inline __attribute__ ((__always_inline__)) void __sincospi(double __x, double *__sinp, double *__cosp);






struct __float2 { float __sinval; float __cosval; };
struct __double2 { double __sinval; double __cosval; };

extern struct __float2 __sincosf_stret(float);
extern struct __double2 __sincos_stret(double);
extern struct __float2 __sincospif_stret(float);
extern struct __double2 __sincospi_stret(double);

inline __attribute__ ((__always_inline__)) void __sincosf(float __x, float *__sinp, float *__cosp) {
    const struct __float2 __stret = __sincosf_stret(__x);
    *__sinp = __stret.__sinval; *__cosp = __stret.__cosval;
}

inline __attribute__ ((__always_inline__)) void __sincos(double __x, double *__sinp, double *__cosp) {
    const struct __double2 __stret = __sincos_stret(__x);
    *__sinp = __stret.__sinval; *__cosp = __stret.__cosval;
}

inline __attribute__ ((__always_inline__)) void __sincospif(float __x, float *__sinp, float *__cosp) {
    const struct __float2 __stret = __sincospif_stret(__x);
    *__sinp = __stret.__sinval; *__cosp = __stret.__cosval;
}

inline __attribute__ ((__always_inline__)) void __sincospi(double __x, double *__sinp, double *__cosp) {
    const struct __double2 __stret = __sincospi_stret(__x);
    *__sinp = __stret.__sinval; *__cosp = __stret.__cosval;
}







extern double j0(double) __attribute__((availability(macos,introduced=10.0))) __attribute__((availability(ios,introduced=3.2)));
extern double j1(double) __attribute__((availability(macos,introduced=10.0))) __attribute__((availability(ios,introduced=3.2)));
extern double jn(int, double) __attribute__((availability(macos,introduced=10.0))) __attribute__((availability(ios,introduced=3.2)));
extern double y0(double) __attribute__((availability(macos,introduced=10.0))) __attribute__((availability(ios,introduced=3.2)));
extern double y1(double) __attribute__((availability(macos,introduced=10.0))) __attribute__((availability(ios,introduced=3.2)));
extern double yn(int, double) __attribute__((availability(macos,introduced=10.0))) __attribute__((availability(ios,introduced=3.2)));
extern double scalb(double, double);
extern int signgam;
# 763 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/math.h" 3 4
struct exception {
    int type;
    char *name;
    double arg1;
    double arg2;
    double retval;
};
# 6 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/src/nvim/math.c" 2

# 1 "/Applications/Xcode-14.1.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/14.0.0/include/stdint.h" 1 3
# 52 "/Applications/Xcode-14.1.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/14.0.0/include/stdint.h" 3
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 1 3 4
# 18 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_int8_t.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_int8_t.h" 3 4
typedef signed char int8_t;
# 19 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_int16_t.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_int16_t.h" 3 4
typedef short int16_t;
# 20 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_int32_t.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_int32_t.h" 3 4
typedef int int32_t;
# 21 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_int64_t.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_int64_t.h" 3 4
typedef long long int64_t;
# 22 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4

# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_uint8_t.h" 1 3 4
# 31 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_uint8_t.h" 3 4
typedef unsigned char uint8_t;
# 24 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_uint16_t.h" 1 3 4
# 31 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_uint16_t.h" 3 4
typedef unsigned short uint16_t;
# 25 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_uint32_t.h" 1 3 4
# 31 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_uint32_t.h" 3 4
typedef unsigned int uint32_t;
# 26 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_uint64_t.h" 1 3 4
# 31 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_uint64_t.h" 3 4
typedef unsigned long long uint64_t;
# 27 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4


typedef int8_t int_least8_t;
typedef int16_t int_least16_t;
typedef int32_t int_least32_t;
typedef int64_t int_least64_t;
typedef uint8_t uint_least8_t;
typedef uint16_t uint_least16_t;
typedef uint32_t uint_least32_t;
typedef uint64_t uint_least64_t;



typedef int8_t int_fast8_t;
typedef int16_t int_fast16_t;
typedef int32_t int_fast32_t;
typedef int64_t int_fast64_t;
typedef uint8_t uint_fast8_t;
typedef uint16_t uint_fast16_t;
typedef uint32_t uint_fast32_t;
typedef uint64_t uint_fast64_t;




# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types.h" 1 3 4
# 33 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/machine/_types.h" 1 3 4
# 34 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/machine/_types.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/_types.h" 1 3 4
# 15 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/_types.h" 3 4
typedef signed char __int8_t;



typedef unsigned char __uint8_t;
typedef short __int16_t;
typedef unsigned short __uint16_t;
typedef int __int32_t;
typedef unsigned int __uint32_t;
typedef long long __int64_t;
typedef unsigned long long __uint64_t;

typedef long __darwin_intptr_t;
typedef unsigned int __darwin_natural_t;
# 48 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/_types.h" 3 4
typedef int __darwin_ct_rune_t;





typedef union {
 char __mbstate8[128];
 long long _mbstateL;
} __mbstate_t;

typedef __mbstate_t __darwin_mbstate_t;


typedef long int __darwin_ptrdiff_t;







typedef long unsigned int __darwin_size_t;





typedef __builtin_va_list __darwin_va_list;





typedef int __darwin_wchar_t;




typedef __darwin_wchar_t __darwin_rune_t;


typedef int __darwin_wint_t;




typedef unsigned long __darwin_clock_t;
typedef __uint32_t __darwin_socklen_t;
typedef long __darwin_ssize_t;
typedef long __darwin_time_t;
# 35 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/machine/_types.h" 2 3 4
# 34 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types.h" 2 3 4
# 55 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types.h" 3 4
typedef __int64_t __darwin_blkcnt_t;
typedef __int32_t __darwin_blksize_t;
typedef __int32_t __darwin_dev_t;
typedef unsigned int __darwin_fsblkcnt_t;
typedef unsigned int __darwin_fsfilcnt_t;
typedef __uint32_t __darwin_gid_t;
typedef __uint32_t __darwin_id_t;
typedef __uint64_t __darwin_ino64_t;

typedef __darwin_ino64_t __darwin_ino_t;



typedef __darwin_natural_t __darwin_mach_port_name_t;
typedef __darwin_mach_port_name_t __darwin_mach_port_t;
typedef __uint16_t __darwin_mode_t;
typedef __int64_t __darwin_off_t;
typedef __int32_t __darwin_pid_t;
typedef __uint32_t __darwin_sigset_t;
typedef __int32_t __darwin_suseconds_t;
typedef __uint32_t __darwin_uid_t;
typedef __uint32_t __darwin_useconds_t;
typedef unsigned char __darwin_uuid_t[16];
typedef char __darwin_uuid_string_t[37];

# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_pthread/_pthread_types.h" 1 3 4
# 57 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_pthread/_pthread_types.h" 3 4
struct __darwin_pthread_handler_rec {
 void (*__routine)(void *);
 void *__arg;
 struct __darwin_pthread_handler_rec *__next;
};

struct _opaque_pthread_attr_t {
 long __sig;
 char __opaque[56];
};

struct _opaque_pthread_cond_t {
 long __sig;
 char __opaque[40];
};

struct _opaque_pthread_condattr_t {
 long __sig;
 char __opaque[8];
};

struct _opaque_pthread_mutex_t {
 long __sig;
 char __opaque[56];
};

struct _opaque_pthread_mutexattr_t {
 long __sig;
 char __opaque[8];
};

struct _opaque_pthread_once_t {
 long __sig;
 char __opaque[8];
};

struct _opaque_pthread_rwlock_t {
 long __sig;
 char __opaque[192];
};

struct _opaque_pthread_rwlockattr_t {
 long __sig;
 char __opaque[16];
};

struct _opaque_pthread_t {
 long __sig;
 struct __darwin_pthread_handler_rec *__cleanup_stack;
 char __opaque[8176];
};

typedef struct _opaque_pthread_attr_t __darwin_pthread_attr_t;
typedef struct _opaque_pthread_cond_t __darwin_pthread_cond_t;
typedef struct _opaque_pthread_condattr_t __darwin_pthread_condattr_t;
typedef unsigned long __darwin_pthread_key_t;
typedef struct _opaque_pthread_mutex_t __darwin_pthread_mutex_t;
typedef struct _opaque_pthread_mutexattr_t __darwin_pthread_mutexattr_t;
typedef struct _opaque_pthread_once_t __darwin_pthread_once_t;
typedef struct _opaque_pthread_rwlock_t __darwin_pthread_rwlock_t;
typedef struct _opaque_pthread_rwlockattr_t __darwin_pthread_rwlockattr_t;
typedef struct _opaque_pthread_t *__darwin_pthread_t;
# 81 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types.h" 2 3 4
# 53 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_intptr_t.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_intptr_t.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/machine/types.h" 1 3 4
# 37 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/machine/types.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/types.h" 1 3 4
# 60 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/types.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_u_int8_t.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_u_int8_t.h" 3 4
typedef unsigned char u_int8_t;
# 61 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/types.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_u_int16_t.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_u_int16_t.h" 3 4
typedef unsigned short u_int16_t;
# 62 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/types.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_u_int32_t.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_u_int32_t.h" 3 4
typedef unsigned int u_int32_t;
# 63 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/types.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_u_int64_t.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_u_int64_t.h" 3 4
typedef unsigned long long u_int64_t;
# 64 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/types.h" 2 3 4


typedef int64_t register_t;




# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_intptr_t.h" 1 3 4
# 72 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/types.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_uintptr_t.h" 1 3 4
# 34 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_uintptr_t.h" 3 4
typedef unsigned long uintptr_t;
# 73 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/types.h" 2 3 4




typedef u_int64_t user_addr_t;
typedef u_int64_t user_size_t;
typedef int64_t user_ssize_t;
typedef int64_t user_long_t;
typedef u_int64_t user_ulong_t;
typedef int64_t user_time_t;
typedef int64_t user_off_t;
# 104 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/arm/types.h" 3 4
typedef u_int64_t syscall_arg_t;
# 38 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/machine/types.h" 2 3 4
# 31 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_intptr_t.h" 2 3 4

typedef __darwin_intptr_t intptr_t;
# 54 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4




# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_intmax_t.h" 1 3 4
# 32 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_intmax_t.h" 3 4
typedef long int intmax_t;
# 59 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_uintmax_t.h" 1 3 4
# 32 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types/_uintmax_t.h" 3 4
typedef long unsigned int uintmax_t;
# 60 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/stdint.h" 2 3 4
# 53 "/Applications/Xcode-14.1.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/14.0.0/include/stdint.h" 2 3
# 8 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/src/nvim/math.c" 2
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 1 3 4
# 61 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types.h" 1 3 4
# 40 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/_types.h" 3 4
typedef int __darwin_nl_item;
typedef int __darwin_wctrans_t;

typedef __uint32_t __darwin_wctype_t;
# 62 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 2 3 4


# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_size_t.h" 1 3 4
# 31 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_size_t.h" 3 4
typedef __darwin_size_t size_t;
# 65 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_null.h" 1 3 4
# 66 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 2 3 4




void *memchr(const void *__s, int __c, size_t __n);
int memcmp(const void *__s1, const void *__s2, size_t __n);
void *memcpy(void *__dst, const void *__src, size_t __n);
void *memmove(void *__dst, const void *__src, size_t __len);
void *memset(void *__b, int __c, size_t __len);
char *strcat(char *__s1, const char *__s2);
char *strchr(const char *__s, int __c);
int strcmp(const char *__s1, const char *__s2);
int strcoll(const char *__s1, const char *__s2);
char *strcpy(char *__dst, const char *__src);
size_t strcspn(const char *__s, const char *__charset);
char *strerror(int __errnum) __asm("_" "strerror" );
size_t strlen(const char *__s);
char *strncat(char *__s1, const char *__s2, size_t __n);
int strncmp(const char *__s1, const char *__s2, size_t __n);
char *strncpy(char *__dst, const char *__src, size_t __n);
char *strpbrk(const char *__s, const char *__charset);
char *strrchr(const char *__s, int __c);
size_t strspn(const char *__s, const char *__charset);
char *strstr(const char *__big, const char *__little);
char *strtok(char *__str, const char *__sep);
size_t strxfrm(char *__s1, const char *__s2, size_t __n);
# 104 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 3 4
char *strtok_r(char *__str, const char *__sep, char **__lasts);
# 116 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 3 4
int strerror_r(int __errnum, char *__strerrbuf, size_t __buflen);
char *strdup(const char *__s1);
void *memccpy(void *__dst, const void *__src, int __c, size_t __n);
# 130 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 3 4
char *stpcpy(char *__dst, const char *__src);
char *stpncpy(char *__dst, const char *__src, size_t __n) __attribute__((availability(macosx,introduced=10.7)));
char *strndup(const char *__s1, size_t __n) __attribute__((availability(macosx,introduced=10.7)));
size_t strnlen(const char *__s1, size_t __n) __attribute__((availability(macosx,introduced=10.7)));
char *strsignal(int __sig);






# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_rsize_t.h" 1 3 4
# 31 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_rsize_t.h" 3 4
typedef __darwin_size_t rsize_t;
# 142 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 2 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_errno_t.h" 1 3 4
# 30 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_errno_t.h" 3 4
typedef int errno_t;
# 143 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 2 3 4


errno_t memset_s(void *__s, rsize_t __smax, int __c, rsize_t __n) __attribute__((availability(macosx,introduced=10.9)));






# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_ssize_t.h" 1 3 4
# 31 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/sys/_types/_ssize_t.h" 3 4
typedef __darwin_ssize_t ssize_t;
# 153 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 2 3 4


void *memmem(const void *__big, size_t __big_len, const void *__little, size_t __little_len) __attribute__((availability(macosx,introduced=10.7)));
void memset_pattern4(void *__b, const void *__pattern4, size_t __len) __attribute__((availability(macosx,introduced=10.5)));
void memset_pattern8(void *__b, const void *__pattern8, size_t __len) __attribute__((availability(macosx,introduced=10.5)));
void memset_pattern16(void *__b, const void *__pattern16, size_t __len) __attribute__((availability(macosx,introduced=10.5)));

char *strcasestr(const char *__big, const char *__little);
char *strnstr(const char *__big, const char *__little, size_t __len);
size_t strlcat(char *__dst, const char *__source, size_t __size);
size_t strlcpy(char *__dst, const char *__source, size_t __size);
void strmode(int __mode, char *__bp);
char *strsep(char **__stringp, const char *__delim);


void swab(const void * restrict, void * restrict, ssize_t);

__attribute__((availability(macosx,introduced=10.12.1))) __attribute__((availability(ios,introduced=10.1)))
__attribute__((availability(tvos,introduced=10.0.1))) __attribute__((availability(watchos,introduced=3.1)))
int timingsafe_bcmp(const void *__b1, const void *__b2, size_t __len);

__attribute__((availability(macosx,introduced=11.0))) __attribute__((availability(ios,introduced=14.0)))
__attribute__((availability(tvos,introduced=14.0))) __attribute__((availability(watchos,introduced=7.0)))
int strsignal_r(int __sig, char *__strsignalbuf, size_t __buflen);







# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/strings.h" 1 3 4
# 70 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/strings.h" 3 4
int bcmp(const void *, const void *, size_t) ;
void bcopy(const void *, void *, size_t) ;
void bzero(void *, size_t) ;
char *index(const char *, int) ;
char *rindex(const char *, int) ;


int ffs(int);
int strcasecmp(const char *, const char *);
int strncasecmp(const char *, const char *, size_t);





int ffsl(long) __attribute__((availability(macosx,introduced=10.5)));
int ffsll(long long) __attribute__((availability(macosx,introduced=10.9)));
int fls(int) __attribute__((availability(macosx,introduced=10.5)));
int flsl(long) __attribute__((availability(macosx,introduced=10.5)));
int flsll(long long) __attribute__((availability(macosx,introduced=10.9)));


# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 1 3 4
# 93 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/strings.h" 2 3 4




# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/secure/_strings.h" 1 3 4
# 33 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/secure/_strings.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/secure/_common.h" 1 3 4
# 34 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/secure/_strings.h" 2 3 4
# 98 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/strings.h" 2 3 4
# 185 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 2 3 4
# 194 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 3 4
# 1 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/secure/_string.h" 1 3 4
# 195 "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk/usr/include/string.h" 2 3 4
# 9 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/src/nvim/math.c" 2

# 1 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/src/nvim/math.h" 1
# 11 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/src/nvim/math.c" 2





int xfpclassify(double d)
{
  uint64_t m;
  int e;

  __builtin___memcpy_chk (&m, &d, sizeof(m), __builtin_object_size (&m, 0));
  e = 0x7ff & (m >> 52);
  m = 0xfffffffffffffULL & m;

  switch (e) {
  default:
    return 4;
  case 0x000:
    return m ? 5 : 3;
  case 0x7ff:
    return m ? 1 : 2;
  }
}

int xisinf(double d)
{
  return 2 == xfpclassify(d);
}

int xisnan(double d)
{
  return 1 == xfpclassify(d);
}
