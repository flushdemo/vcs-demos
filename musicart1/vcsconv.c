/*
 * PNG conversion tool for VCS.
 *
 * compile with, $CC being either gcc or clang:
 *   $CC -std=c99 -fno-strict-aliasing -lm -o vcsconv vcsconv.c
 */

#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 700

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <inttypes.h>
#include <libgen.h>
#include <getopt.h>
#include <unistd.h>

#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
#define STBI_NO_FAILURE_STRINGS
#include "stb_image.h"

#define CMD_START "$vcsconv$"
#define CMD_END   "$vnocscv$"

#define USAGE_HELP      "  -h, --help               display this message and exit\n"
#define USAGE_FORMAT    "  -f, --format format      output table as k65, ca65, dasm or bin [auto,k65]\n"
#define USAGE_OUTPUT    "  -o, --output filename    output filename [stdout]\n"
#define USAGE_FIELD     "  -n, --name name          output field name [auto]\n"
#define USAGE_DATA      "  -d, --data               output only the data, no field nor directives\n"
#define USAGE_X0        "  -x0                      scan x start offset [0]\n"
#define USAGE_Y0        "  -y0                      scan y start offset [0]\n"
#define USAGE_X1        "  -x1                      scan x end offset [image width]\n"
#define USAGE_Y1        "  -y1                      scan y end offset [image height]\n"
#define USAGE_XI        "  -xi                      scan x next pixel increment [1]\n"
#define USAGE_YI        "  -yi                      scan y next pixel increment [1]\n"
const char *program_name;
static void print_usage(FILE *stream, int exit_code)
{
    fprintf(stream, "VCS conversion utilities.\n");
    fprintf(stream, "Usage: %s command <params>\n", program_name);
    fprintf(stream, "command list:\n"
        "  authpalette      generate a palette for authoring software\n"
        "  linecol          generate a table containing the first color of each line\n"
        "  playfield        convert pixels to playfield tables\n"
        "  scramble         reorder ramdomly a table\n"
        "  sprite           convert pixels to sprite tables\n"
    );
    exit(exit_code);
}

static void err(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);
    exit(EXIT_FAILURE);
}

static void readfile(const char *filename, void **b, size_t *b_sz)
{
    FILE *file = fopen(filename, "rb"); if (!file) err("failed to open file %s\n", filename);
    fseek(file, 0, SEEK_END);
    size_t sz = ftell(file);
    fseek(file, 0, SEEK_SET);
    *b = malloc(sz + 1); ((char*)(*b))[sz] = 0; // null terminate it for strings
    fread(*b, sz, 1, file);
    fclose(file);
    if (b_sz) *b_sz = sz;
}

static int s_dataonly = 0;
static int s_w, s_h;
static uint8_t *s_px = 0, *s_lncol;

static int r_s32be(uint8_t **b) { uint8_t *p = *b; int v = ((int)(p[0]))<<24 | ((int)(p[1]))<<16 | ((int)p[2])<<8 | p[3]; *b += 4; return v; }
typedef struct { int len, nam; } chunk_s;
static chunk_s r_chunk(uint8_t **b) { int len = r_s32be(b), nam = r_s32be(b); chunk_s c = { len, nam }; return c; }
#define CHUNK_NAM(a,b,c,d) (((a) << 24) + ((b) << 16) + ((c) << 8) + (d))
static void open_png(const char *filename)
{
    uint8_t *b;
    readfile(filename, (void**)&b, 0);
    static uint8_t png_sig[8] = { 137,80,78,71,13,10,26,10 };
    if (memcmp(b, png_sig, 8) != 0) { fprintf(stderr, "input is not a PNG\n"); exit(EXIT_FAILURE); }
    b += 8;
    int w, h;
    uint8_t *d = 0; long d_sz = 0;
    for (;;)
    {
        chunk_s chunk = r_chunk(&b);
        switch (chunk.nam)
        {
            case CHUNK_NAM('I','H','D','R'): {
                w = r_s32be(&b); h = r_s32be(&b);
                if (b[0] != 8 || b[1] != 3) err("input PNG must be 8b indexed");
                b += 9;
            } break;
            case CHUNK_NAM('I','D','A','T'): {
                d = realloc(d, d_sz + chunk.len);
                memcpy(d + d_sz, b, chunk.len);
                d_sz += chunk.len;
                b += chunk.len+4;
            } break;
            case CHUNK_NAM('I','E','N','D'): {
                if (!d) err("invalid PNG");
                int px_sz;
                uint8_t *px_raw = (uint8_t*)stbi_zlib_decode_malloc_guesssize_headerflag((void*)d, d_sz, (w+1) * h, &px_sz, 1);
                uint8_t *px = calloc(w+1,h+1), *r0 = px;
                px += w+h;
                for (int y = 0; y < h; ++y)
                {
                    int filter = *px_raw++;
                    #define prev (x==0 ? 0 : px[x-1])
                    #define up (px[x-w])
                    #define prevup (x==0 ? 0 : px[x-w-1])
                    switch (filter)
                    {
                        case 0: memcpy(px, px_raw, w); break;
                        case 1: for (int x = 0; x < w; ++x) { px[x] = px_raw[x] + prev; } break;
                        case 2: for (int x = 0; x < w; ++x) { px[x] = px_raw[x] + up; } break;
                        case 3: for (int x = 0; x < w; ++x) { px[x] = px_raw[x] + ((prev+up)>>1); } break;
                        case 4: for (int x = 0; x < w; ++x) { px[x] = px_raw[x] + stbi__paeth(prev,up,prevup); } break;
                    }
                    #undef prev
                    #undef up
                    #undef prevup
                    px += w;
                    px_raw += w;
                }
                px = r0 + w+h;
                for (int y = 0; y < h; ++y)
                    for (int x = 0; x < w; ++x)
                        if (px[y*w + x]) { r0[y] = px[y*w + x]; break; }
                s_w = w, s_h = h;
                s_px = px, s_lncol = r0;
            } return;
            default:
                b += chunk.len+4;
        }
    }
    err("invalid PNG");
}

typedef enum { PAL_AUTO, PAL_ACT, PAL_GPL } pal_t;
typedef enum { FMT_AUTO, FMT_K65, FMT_CA65, FMT_DASM, FMT_BIN } format_t;
static const char *format_names[] = { "auto", "k65", "ca65", "dasm", "bin" };

#define CMD_START_WRITE if (output_format != FMT_BIN) fprintf(output_file, "%s " CMD_START " ", output_format == FMT_K65 ? "//" : ";");
#define CMD_END_WRITE if (output_format != FMT_BIN) fprintf(output_file, "\n%s " CMD_END "\n", output_format == FMT_K65 ? "//" : ";");

#define OX0 0x100
#define OY0 0x101
#define OX1 0x102
#define OY1 0x103
#define OXI 0x104
#define OYI 0x105

#define OPT_HELP    { "help",             no_argument, 0, 'h' }
#define OPT_FORMAT  { "format",     required_argument, 0, 'f' }
#define OPT_OUTPUT  { "output",     required_argument, 0, 'o' }
#define OPT_FIELD   { "name",       required_argument, 0, 'n' }
#define OPT_DATA    { "data",             no_argument, 0, 'd' }
#define OPT_X0      { "x0",         required_argument, 0,  OX0 }
#define OPT_Y0      { "y0",         required_argument, 0,  OY0 }
#define OPT_X1      { "x1",         required_argument, 0,  OX1 }
#define OPT_Y1      { "y1",         required_argument, 0,  OY1 }
#define OPT_XI      { "xi",         required_argument, 0,  OXI }
#define OPT_YI      { "yi",         required_argument, 0,  OYI }

#define case_fmt case 'f': if ((output_format = parse_format(optarg)) < 0) err("invalid format: %s\n", optarg); break;
#define case_field case 'n': field_name = strdup(optarg); break;
#define case_data case 'd': s_dataonly = 1; break;
#define case_ox0 case OX0: x0 = atoi(optarg); break;
#define case_oy0 case OY0: y0 = atoi(optarg); break;
#define case_ox1 case OX1: x1 = atoi(optarg); break;
#define case_oy1 case OY1: y1 = atoi(optarg); break;
#define case_oxi case OXI: xi = atoi(optarg); break;
#define case_oyi case OYI: yi = atoi(optarg); break;

static format_t parse_format(const char *format_str)
{
    int i;
    for (i = 0; i < sizeof(format_names) / sizeof(*format_names) && strcmp(format_str, format_names[i]); ++i) {}
    if (i == sizeof(format_names) / sizeof(*format_names)) return -1;
    return i;
}
static void get_format(format_t *format, const char *filename)
{
    if (*format == FMT_AUTO)
    {
        if (filename)
        {
            const char *ext = strrchr(filename, '.');
            if (ext && ext != filename) *format = parse_format(++ext);
        }
        if (*format <= FMT_AUTO) *format = FMT_K65;
    }
}

static char *get_field_name(const char *input_filename, char *field_name, const char *fmt, ...)
{
    char *d = malloc(256);
    if (!field_name)
    {
        field_name = basename(strdup(input_filename));
        char *field_dot = strrchr(field_name, '.'); if (field_dot) *field_dot = 0;
    }
    int o = sprintf(d, "%.128s", field_name);
    va_list args;
    va_start(args, fmt);
    vsprintf(d + o, fmt, args);
    va_end(args);
    return d;
}

static void write_table_start(FILE *stream, format_t format, const char *field_name)
{
    if (s_dataonly) return;
    switch (format)
    {
        case FMT_K65: fprintf(stream, "\ndata %s {\n    nocross", field_name); break;
        case FMT_CA65: fprintf(stream, "\n    .segment RODATA_SEGMENT\n    .align 256\n%s:", field_name); break;
        case FMT_DASM: fprintf(stream, "\n    ALIGN $100\n%s", field_name); break;
        default: break;
    }
}
static void write_table_end(FILE *stream, format_t format)
{
    if (s_dataonly) return;
    switch (format)
    {
        case FMT_K65: fprintf(stream, "\n}"); break;
        default: break;
    }
}
static void write_table_data(FILE *stream, format_t format, uint8_t *b, int b_sz)
{
    switch (format)
    {
        case FMT_K65: for (int i = 0; i < b_sz; ++i) fprintf(stream, "%s0x%02X", !(i%16) ? "\n    " : " ", b[i]); break;
        case FMT_CA65: for (int i = 0; i < b_sz; ++i) fprintf(stream, "%s$%02X", !(i%16) ? "\n    .byte " : ",", b[i]); break;
        case FMT_DASM: for (int i = 0; i < b_sz; ++i) fprintf(stream, "%s$%02X", !(i%16) ? "\n    dc.b " : ",", b[i]); break;
        case FMT_BIN: fwrite(b, 1, b_sz, stream); break;
        default: break;
    }
}
static void write_table(FILE *stream, format_t format, const char *field_name, uint8_t *b, int b_sz)
{
    write_table_start(stream, format, field_name);
    write_table_data(stream, format, b, b_sz);
    write_table_end(stream, format);
}

static void print_usage_authpalette(FILE *stream, int exit_code)
{
    fprintf(stream, "Generate a palette from an image.\n");
    fprintf(stream, "Usage: %s authpalette options <png>\n", program_name);
    fprintf(stream,
        USAGE_HELP
        USAGE_OUTPUT
        "  -f, --format format      output palette as act or gpl [act]\n"
        "  -r, --repeat #n          output each color n times [1]\n"
        USAGE_X0 USAGE_Y0 USAGE_X1 USAGE_Y1 USAGE_XI USAGE_YI
    );
    exit(exit_code);
}
static void cmd_authpalette(int argc, char **argv)
{
    const char *const short_options = "ho:f:r:";
    const struct option long_options[] = {
        OPT_HELP, OPT_OUTPUT, OPT_FORMAT,
        { "repeat", required_argument, 0, 'r' },
        OPT_X0, OPT_Y0, OPT_X1, OPT_Y1, OPT_XI, OPT_YI,
        { 0, 0, 0, 0 },
    };
    const char *output_filename = 0;
    pal_t output_format = PAL_AUTO;
    int x0 = 0, y0 = 0, x1 = -1, y1 = -1, xi = 1, yi = 1;
    int repeat = 1;
    for (;;)
    {
        int next_option = getopt_long_only(argc, argv, short_options, long_options, 0);
        if (next_option < 0) break;
        switch (next_option)
        {
            case 'o': output_filename = optarg; break;
            case 'f': 
                if (!strcmp(optarg, "act")) output_format = PAL_ACT;
                else if (!strcmp(optarg, "gpl")) output_format = PAL_GPL;
                else err("invalid format: %s\n", optarg);
                break;
            case 'r': repeat = atoi(optarg); if (repeat <= 0) err("repeat count must be positive\n"); break;
            case_ox0 case_oy0 case_ox1 case_oy1 case_oxi case_oyi
            case 0: break;
            case 'h': print_usage_authpalette(stdout, EXIT_SUCCESS);
            case '?': case ':': print_usage_authpalette(stderr, EXIT_FAILURE);
            default: abort();
        }
    }
    const char *input_filename = argv[optind];
    if (argc <= optind || !*input_filename) err("no input\n");
    if (output_format == PAL_AUTO)
    {
        const char *ext = strrchr(output_filename, '.');
        if (ext && ext != output_filename)
        {
            ++ext;
            if (!strcmp(ext, "act")) output_format = PAL_ACT;
            else if (!strcmp(ext, "gpl")) output_format = PAL_GPL;
        }
        if (output_format == PAL_AUTO) err("unable to detect output palette format\n");
    }

    int width, height;
    uint8_t *px = stbi_load(input_filename, &width, &height, 0, 3);
    if (!px) err("unable to load input file %s\n", input_filename);
    int flipx = 0, flipy = 0;
    if (x1 < 0) x1 = width; if (y1 < 0) y1 = height;
    if (x1 < x0 && xi < 0) { int t = x1; x1 = x0; x0 = t; xi = -xi; flipx = 1; }
    if (y1 < y0 && yi < 0) { int t = y1; y1 = y0; y0 = t; yi = -yi; flipy = 1; }
    if (y1 <= y0 || x1 <= x0 || x1 > width || y1 > height) err("invalid dimensions\n");
    int col_h = 1 + (y1-1 - y0) / yi, col_w = 1 + (x1-1 - x0) / xi;
    int col_count = repeat * col_h * col_w;
    uint8_t *pal = malloc(3 * col_count), *p = pal;
    for (int y = y0; y < y1; y += yi)
    {
        uint8_t *b = px + 3 * (y * width + x0);
        for (int x = x0; x < x1; x += xi, b += xi * 3)
            for (int r = 0; r < repeat; ++r, p += 3)
                p[0] = b[0], p[1] = b[1], p[2] = b[2];
    }
    if (flipx) for (int y = 0; y < col_h; ++y) for (int x = 0; x < col_w/2; ++x)
    {
        int t, o = 3 * (y * col_w + x), u = 3 * (y * col_w + (col_w-1 - x));
        t = p[o]; p[o] = p[u]; p[u] = t; ++o; ++u;
        t = p[o]; p[o] = p[u]; p[u] = t; ++o; ++u;
        t = p[o]; p[o] = p[u]; p[u] = t;
    }
    if (flipy) for (int y = 0; y < col_h/2; ++y) for (int x = 0; x < col_w; ++x)
    {
        int t, o = 3 * (y * col_w + x), u = 3 * ((col_h-1 - y) * col_w + x);
        t = p[o]; p[o] = p[u]; p[u] = t; ++o; ++u;
        t = p[o]; p[o] = p[u]; p[u] = t; ++o; ++u;
        t = p[o]; p[o] = p[u]; p[u] = t;
    }

    FILE *output_file = stdout;
    if (output_filename && !(output_file = fopen(output_filename, "wb"))) err("failed to open output %s\n", output_filename);
    if (output_format == PAL_ACT)
    {
        int i = 0;
        for (int o = 0; i < col_count && i < 256; ++i, pal += 3)
            fwrite(pal, 1, 3, output_file);
        for (int v = 0; i < 256; ++i)
            fwrite(&v, 1, 3, output_file);
    }
    else if (output_format == PAL_GPL)
    {
        fprintf(output_file, "GIMP Palette\nName: %s\nColumns: 0\n#\n", "VCS Palette");
        for (int i = 0, o = 0; i < col_count; ++i, pal += 3)
            fprintf(output_file, "%*d %*d %*d Untitled\n", 3, pal[0], 3, pal[1], 3, pal[2]);
    }
}

static void print_usage_linecol(FILE *stream, int exit_code)
{
    fprintf(stream, "Export first line color table.\n");
    fprintf(stream, "Usage: %s linecol options <png>\n", program_name);
    fprintf(stream,
        USAGE_HELP USAGE_OUTPUT USAGE_FORMAT USAGE_FIELD USAGE_DATA
        USAGE_Y0 USAGE_Y1 USAGE_YI
    );
    exit(exit_code);
}
static void cmd_linecol(int argc, char **argv)
{
    const char *const short_options = "ho:f:n:d";
    const struct option long_options[] = {
        OPT_HELP, OPT_OUTPUT, OPT_FORMAT, OPT_FIELD, OPT_DATA,
        OPT_Y0, OPT_Y1, OPT_YI,
        { 0, 0, 0, 0 },
    };
    const char *output_filename = 0;
    format_t output_format = FMT_AUTO;
    char *field_name = 0;
    int y0 = 0, y1 = -1, yi = 1;
    int repeat = 1;
    for (;;)
    {
        int next_option = getopt_long_only(argc, argv, short_options, long_options, 0);
        if (next_option < 0) break;
        switch (next_option)
        {
            case 'o': output_filename = optarg; break;
            case_fmt case_field case_data
            case_oy0 case_oy1 case_oyi
            case 0: break;
            case 'h': print_usage_linecol(stdout, EXIT_SUCCESS);
            case '?': case ':': print_usage_linecol(stderr, EXIT_FAILURE);
            default: abort();
        }
    }
    const char *input_filename = argv[optind];
    if (argc <= optind || !*input_filename) err("no input\n");
    get_format(&output_format, output_filename);
    open_png(input_filename);

    FILE *output_file = stdout;
    if (output_filename && !(output_file = fopen(output_filename, "wb"))) err("failed to open output %s\n", output_filename);
    CMD_START_WRITE
    if (output_format != FMT_BIN)
    {
        fprintf(output_file, "linecol");
        if (s_dataonly) fprintf(output_file, " -d");
        if (field_name) fprintf(output_file, " -n %s", field_name);
        if (output_format != FMT_K65) fprintf(output_file, " -f %s", format_names[output_format]);
        if (y0 != 0) fprintf(output_file, " -y0 %d", y0); if (y1 != -1) fprintf(output_file, " -y1 %d", y1); if (yi != 1) fprintf(output_file, " -yi %d", yi);
        fprintf(output_file, " %s", input_filename);
    }
    int flipy = 0;
    if (y1 < 0) y1 = s_h;
    if (y1 < y0 && yi < 0) { int t = y1; y1 = y0; y0 = t; yi = -yi; flipy = 1; }
    if (y1 <= y0 || y1 > s_h) err("invalid dimensions\n");
    int b_sz = 1 + (y1-1 - y0) / yi;
    uint8_t *b = malloc(b_sz);
    for (int y = y0, i = 0; y < y1; y += yi) b[i++] = s_lncol[y];
    if (flipy) { uint8_t *d = malloc(b_sz); for (int i = 0; i < b_sz; ++i) d[i] = b[b_sz-1 - i]; b = d; }
    field_name = get_field_name(input_filename, field_name, "_col");
    write_table(output_file, output_format, field_name, b, b_sz);
    CMD_END_WRITE
}

static void print_usage_playfield(FILE *stream, int exit_code)
{
    fprintf(stream, "Export playfield data.\n");
    fprintf(stream, "Usage: %s playfield options <png>\n", program_name);
    fprintf(stream,
        USAGE_HELP USAGE_OUTPUT USAGE_FORMAT USAGE_FIELD USAGE_DATA
        "  -r, --reverse            switch playfield bits\n"
        "  -s, --select 012345      output only set PF, eg. 012 outputs only the left half\n"
        USAGE_X0 USAGE_Y0 USAGE_X1 USAGE_Y1 USAGE_XI USAGE_YI
    );
    exit(exit_code);
}
static void cmd_playfield(int argc, char **argv)
{
    const char *const short_options = "ho:f:n:s:d";
    const struct option long_options[] = {
        OPT_HELP, OPT_OUTPUT, OPT_FORMAT, OPT_FIELD, OPT_DATA,
        { "reverse", no_argument, 0, 'r' },
        { "select", required_argument, 0, 's' },
        OPT_X0, OPT_Y0, OPT_X1, OPT_Y1, OPT_XI, OPT_YI,
        { 0, 0, 0, 0 },
    };
    const char *output_filename = 0;
    format_t output_format = FMT_AUTO;
    char *field_name = 0;
    int x0 = 0, y0 = 0, x1 = -1, y1 = -1, xi = 1, yi = 1;
    int reverse = 0;
    int pfmask = 0x3F;
    char *pfmask_str = 0;
    for (;;)
    {
        int next_option = getopt_long_only(argc, argv, short_options, long_options, 0);
        if (next_option < 0) break;
        switch (next_option)
        {
            case 'o': output_filename = optarg; break;
            case_fmt case_field case_data
            case 'r': reverse = 1; break;
            case 's':
                pfmask_str = strdup(optarg);
                for (int i = 0; i < 6; ++i) if (strchr(optarg,'0'+i)) pfmask ^= 1<<i;
                if (pfmask != 0x3F) pfmask = ~pfmask;
                break;
            case_ox0 case_oy0 case_ox1 case_oy1 case_oxi case_oyi
            case 0: break;
            case 'h': print_usage_playfield(stdout, EXIT_SUCCESS);
            case '?': case ':': print_usage_playfield(stderr, EXIT_FAILURE);
            default: abort();
        }
    }
    const char *input_filename = argv[optind];
    if (argc <= optind || !*input_filename) err("no input\n");
    get_format(&output_format, output_filename);
    open_png(input_filename);

    FILE *output_file = stdout;
    if (output_filename && !(output_file = fopen(output_filename, "wb"))) err("failed to open output %s\n", output_filename);
    CMD_START_WRITE
    if (output_format != FMT_BIN)
    {
        fprintf(output_file, "playfield");
        if (s_dataonly) fprintf(output_file, " -d");
        if (field_name) fprintf(output_file, " -n %s", field_name);
        if (output_format != FMT_K65) fprintf(output_file, " -f %s", format_names[output_format]);
        if (pfmask_str) fprintf(output_file, " -s %s", pfmask_str);
        if (reverse) fprintf(output_file, " -r");
        if (x0 != 0) fprintf(output_file, " -x0 %d", x0); if (x1 != -1) fprintf(output_file, " -x1 %d", x1); if (xi != 1) fprintf(output_file, " -xi %d", xi);
        if (y0 != 0) fprintf(output_file, " -y0 %d", y0); if (y1 != -1) fprintf(output_file, " -y1 %d", y1); if (yi != 1) fprintf(output_file, " -yi %d", yi);
        fprintf(output_file, " %s", input_filename);
    }
    int flipx = 0, flipy = 0;
    if (x1 < 0) x1 = s_w; if (y1 < 0) y1 = s_h;
    if (x1 < x0 && xi < 0) { int t = x1; x1 = x0; x0 = t; xi = -xi; flipx = 1; }
    if (y1 < y0 && yi < 0) { int t = y1; y1 = y0; y0 = t; yi = -yi; flipy = 1; }
    if (y1 <= y0 || x1 <= x0 || x1 > s_w || y1 > s_h) err("invalid dimensions\n");
    int col_h = 1 + (y1-1 - y0) / yi, col_w = 1 + (x1-1 - x0) / xi, b_sz = col_h * col_w;
    uint8_t *b = malloc(b_sz);
    for (int y = y0, i = 0; y < y1; y += yi) for (int x = x0; x < x1; x += xi) b[i++] = s_px[y * s_w + x];
    if (flipx) for (int y = 0; y < col_h; ++y) for (int x = 0; x < col_w/2; ++x)
        { int i0 = y*col_w + x, i1 = y*col_w + col_w-1 - x; uint8_t t = b[i0]; b[i0] = b[i1]; b[i1] = t; }
    if (flipy) for (int y = 0; y < col_h/2; ++y) for (int x = 0; x < col_w; ++x)
        { int i0 = y*col_w + x, i1 = (col_h-1 - y)*col_w + x; uint8_t t = b[i0]; b[i0] = b[i1]; b[i1] = t; }
    uint8_t *pf = calloc(6,col_h);
    #define PF(i) (&pf[i*col_h])
    #define x(o,s) (!!b[i+o]<<s)
    for (int y = 0, i = 0; y < col_h; ++y, i += col_w)
    {
        PF(0)[y] = x( 0,4)|x( 1,5)|x( 2,6)|x( 3,7);
        PF(1)[y] = x( 4,7)|x( 5,6)|x( 6,5)|x( 7,4)|x( 8,3)|x( 9,2)|x(10,1)|x(11,0);
        PF(2)[y] = x(12,0)|x(13,1)|x(14,2)|x(15,3)|x(16,4)|x(17,5)|x(18,6)|x(19,7);
        PF(3)[y] = x(20,4)|x(21,5)|x(22,6)|x(23,7);
        PF(4)[y] = x(24,7)|x(25,6)|x(26,5)|x(27,4)|x(28,3)|x(29,2)|x(30,1)|x(31,0);
        PF(5)[y] = x(32,0)|x(33,1)|x(34,2)|x(35,3)|x(36,4)|x(37,5)|x(38,6)|x(39,7);
    }
    #undef x
    for (int i = 0; i < 6; ++i)
    {
        if (!(pfmask & (1<<i))) continue;
        char *fname = get_field_name(input_filename, field_name, "_pf%d", i);
        if (reverse) for (int j = 0; j < col_h; ++j) PF(i)[j] ^= 0xff;
        write_table(output_file, output_format, fname, PF(i), col_h);
    }
    CMD_END_WRITE
}

static void print_usage_scramble(FILE *stream, int exit_code)
{
    fprintf(stream, "Generate a scrambled table.\n");
    fprintf(stream, "Usage: %s scramble options <png>\n", program_name);
    fprintf(stream,
        USAGE_HELP USAGE_OUTPUT USAGE_FORMAT USAGE_FIELD USAGE_DATA
        "  --min <int>          lower bound, inclusive [0]\n"
        "  --max <int>          higher bound, inclusive [255]\n"
        "  --seed <int>         random seed\n"
    );
    exit(exit_code);
}
#define OMIN 0x201
#define OMAX 0x202
#define OSEED 0x203
#define OPT_MIN      { "min",         required_argument, 0,  OMIN }
#define OPT_MAX      { "max",         required_argument, 0,  OMAX }
#define OPT_SEED     { "seed",        required_argument, 0,  OSEED }
#define OPT_REVERSE  { "reverse",     no_argument,       0,  'r' }
#define case_omin case OMIN: range_min = atoi(optarg); break;
#define case_omax case OMAX: range_max = atoi(optarg); break;
#define case_oseed case OSEED: rand_seed = strtoul(optarg, 0, 16); break;
static void cmd_scramble(int argc, char **argv)
{
    const char *const short_options = "ho:f:n:d";
    const struct option long_options[] = {
        OPT_HELP, OPT_OUTPUT, OPT_FORMAT, OPT_FIELD, OPT_DATA,
        OPT_MIN, OPT_MAX, OPT_SEED, OPT_REVERSE,
        { 0, 0, 0, 0 },
    };
    const char *output_filename = 0;
    format_t output_format = FMT_AUTO;
    char *field_name = 0;
    int range_min = 0, range_max=255, rand_seed = 0;
    int reverse = 0;
    for (;;)
    {
        int next_option = getopt_long_only(argc, argv, short_options, long_options, 0);
        if (next_option < 0) break;
        switch (next_option)
        {
            case 'o': output_filename = optarg; break;
            case_fmt case_field case_data
            case_omin case_omax case_oseed
            case 'r': reverse = 1; break;
            case 0: break;
            case 'h': print_usage_scramble(stdout, EXIT_SUCCESS);
            case '?': case ':': print_usage_scramble(stderr, EXIT_FAILURE);
            default: abort();
        }
    }
    get_format(&output_format, output_filename);

    FILE *output_file = stdout;
    if (output_filename && !(output_file = fopen(output_filename, "wb"))) err("failed to open output %s\n", output_filename);
    CMD_START_WRITE
    if (output_format != FMT_BIN)
    {
        fprintf(output_file, "scramble");
        if (s_dataonly) fprintf(output_file, " -d");
        if (field_name) fprintf(output_file, " -n %s", field_name);
        if (reverse) fprintf(output_file, " -r");
        if (output_format != FMT_K65) fprintf(output_file, " -f %s", format_names[output_format]);
        if (range_min != 0) fprintf(output_file, " --min %d", range_min); if (range_max != 255) fprintf(output_file, " --max %d", range_max);
        if (rand_seed != 0) fprintf(output_file, " --seed 0x%08X", rand_seed);
    }
    int count = range_max - range_min + 1;
    uint8_t *b = malloc(count);
    for (int i = 0; i < count; ++i) b[i] = (uint8_t)(i + range_min);
    if (!rand_seed) rand_seed = getpid() + (time(0) << (8 * sizeof(pid_t)));
    srand(rand_seed);
    for (int i = 0; i < count; ++i)
    {
        int j = rand() % (count - i) + i;
        uint8_t t = b[i]; b[i] = b[j]; b[j] = t;
    }
    write_table_start(output_file, output_format, field_name);
    write_table_data(output_file, output_format, b, count);
    if (reverse)
    {
        uint8_t *p = malloc(count);
        for (int i = 0; i < count; ++i)
            p[b[i] - range_min] = i;
        fprintf(output_file, "\n%s_rev:", field_name);
        write_table_data(output_file, output_format, p, count);
    }
    write_table_end(output_file, output_format);
    CMD_END_WRITE
}

static void print_usage_sprite(FILE *stream, int exit_code)
{
    fprintf(stream, "Export sprite data.\n");
    fprintf(stream, "Usage: %s sprite options <png>\n", program_name);
    fprintf(stream,
        USAGE_HELP USAGE_OUTPUT USAGE_FORMAT USAGE_FIELD USAGE_DATA
        USAGE_X0 USAGE_Y0 USAGE_X1 USAGE_Y1 USAGE_XI USAGE_YI
    );
    exit(exit_code);
}
static void cmd_sprite(int argc, char **argv)
{
    const char *const short_options = "ho:f:n:d";
    const struct option long_options[] = {
        OPT_HELP, OPT_OUTPUT, OPT_FORMAT, OPT_FIELD, OPT_DATA,
        OPT_X0, OPT_Y0, OPT_X1, OPT_Y1, OPT_XI, OPT_YI,
        { 0, 0, 0, 0 },
    };
    const char *output_filename = 0;
    format_t output_format = FMT_AUTO;
    char *field_name = 0;
    int x0 = 0, y0 = 0, x1 = -1, y1 = -1, xi = 1, yi = 1;
    for (;;)
    {
        int next_option = getopt_long_only(argc, argv, short_options, long_options, 0);
        if (next_option < 0) break;
        switch (next_option)
        {
            case 'o': output_filename = optarg; break;
            case_fmt case_field case_data
            case_ox0 case_oy0 case_ox1 case_oy1 case_oxi case_oyi
            case 0: break;
            case 'h': print_usage_sprite(stdout, EXIT_SUCCESS);
            case '?': case ':': print_usage_sprite(stderr, EXIT_FAILURE);
            default: abort();
        }
    }
    const char *input_filename = argv[optind];
    if (argc <= optind || !*input_filename) err("no input\n");
    get_format(&output_format, output_filename);
    open_png(input_filename);

    FILE *output_file = stdout;
    if (output_filename && !(output_file = fopen(output_filename, "wb"))) err("failed to open output %s\n", output_filename);
    CMD_START_WRITE
    if (output_format != FMT_BIN)
    {
        fprintf(output_file, "sprite");
        if (s_dataonly) fprintf(output_file, " -d");
        if (field_name) fprintf(output_file, " -n %s", field_name);
        if (output_format != FMT_K65) fprintf(output_file, " -f %s", format_names[output_format]);
        if (x0 != 0) fprintf(output_file, " -x0 %d", x0); if (x1 != -1) fprintf(output_file, " -x1 %d", x1); if (xi != 1) fprintf(output_file, " -xi %d", xi);
        if (y0 != 0) fprintf(output_file, " -y0 %d", y0); if (y1 != -1) fprintf(output_file, " -y1 %d", y1); if (yi != 1) fprintf(output_file, " -yi %d", yi);
        fprintf(output_file, " %s", input_filename);
    }
    int flipx = 0, flipy = 0;
    if (x1 < 0) x1 = s_w; if (y1 < 0) y1 = s_h;
    if (x1 < x0 && xi < 0) { int t = x1; x1 = x0; x0 = t; xi = -xi; flipx = 1; }
    if (y1 < y0 && yi < 0) { int t = y1; y1 = y0; y0 = t; yi = -yi; flipy = 1; }
    if (y1 <= y0 || x1 <= x0 || x1 > s_w || y1 > s_h) err("invalid dimensions\n");
    int col_h = 1 + (y1-1 - y0) / yi, col_w = 1 + (x1-1 - x0) / xi, b_sz = col_h * col_w;
    uint8_t *b = malloc(b_sz);
    for (int y = y0, i = 0; y < y1; y += yi) for (int x = x0; x < x1; x += xi) b[i++] = s_px[y * s_w + x];
    if (flipx) for (int y = 0; y < col_h; ++y) for (int x = 0; x < col_w/2; ++x)
        { int i0 = y*col_w + x, i1 = y*col_w + col_w-1 - x; uint8_t t = b[i0]; b[i0] = b[i1]; b[i1] = t; }
    if (flipy) for (int y = 0; y < col_h/2; ++y) for (int x = 0; x < col_w; ++x)
        { int i0 = y*col_w + x, i1 = (col_h-1 - y)*col_w + x; uint8_t t = b[i0]; b[i0] = b[i1]; b[i1] = t; }
    int column_count = (col_w + 7) / 8;
    uint8_t *s = malloc(col_h);
    char *fname = get_field_name(input_filename, field_name, "");
    write_table_start(output_file, output_format, fname);
    for (int c = 0; c < column_count; ++c)
    {
        if (output_format != FMT_BIN && column_count > 1) fprintf(output_file, "\n");
        memset(s, 0, col_h);
        for (int y = 0; y < col_h; ++y)
        {
            for (int i = 7, x = c * 8, xe = x+8 > col_w ? col_w : x+8; x != xe; ++x, --i)
                if (b[y*col_w + x]) s[y] |= 1 << i;
        }
        write_table_data(output_file, output_format, s, col_h);
    }
    write_table_end(output_file, output_format);
    CMD_END_WRITE
}

static void print_usage_update(FILE *stream, int exit_code)
{
    fprintf(stream, "Scan built asm file and rebuild generated assets from source.\n");
    fprintf(stream, "Usage: %s update options <file>\n", program_name);
    fprintf(stream,
        USAGE_HELP
    );
    exit(exit_code);
}
static void cmd_update(int argc, char **argv)
{
    const char *const short_options = "h";
    const struct option long_options[] = {
        OPT_HELP,
        { 0, 0, 0, 0 },
    };
    for (;;)
    {
        int next_option = getopt_long_only(argc, argv, short_options, long_options, 0);
        if (next_option < 0) break;
        switch (next_option)
        {
            case 0: break;
            case 'h': print_usage_update(stdout, EXIT_SUCCESS);
            case '?': case ':': print_usage_update(stderr, EXIT_FAILURE);
            default: abort();
        }
    }
    const char *input_filename = argv[optind];
    if (argc <= optind || !*input_filename) err("no input\n");
    char *b; size_t b_sz;
    readfile(input_filename, (void**)&b, &b_sz);
    char *org = strdup(b);

    char *output = malloc(1); size_t output_sz = 1, output_of = 0;
    #define cpy(sz) { output = realloc(output, output_sz += sz); memcpy(output + output_of, b, sz); output_of += sz; b += sz; b_sz -= sz; }
    for (char *e = b + b_sz; b < e;)
    {
        char *cmd = strstr(b, CMD_START), *cmd_line, *cmd_end;
        if (!cmd) { cpy(b_sz); break; }
        cmd_line = cmd; while (*--cmd_line != '\n' && cmd_line != b) {} if (cmd_line != b || *cmd_line == '\n') ++cmd_line;
        ptrdiff_t o = cmd_line - b; cpy(o);
        cmd += strlen(CMD_START);
        cmd_end = strchr(cmd, '\n');
        if (cmd_end) { *cmd_end = 0; o = cmd_end - b + 1; b += o; b_sz -= o; }
        else { cmd_end = cmd + b_sz; b += b_sz; b_sz = 0; }
        char pcmd[cmd_end - cmd + strlen(program_name)];
        strcpy(pcmd, program_name);
        strcat(pcmd, cmd);
        FILE *p = popen(pcmd, "r"); if (!p) err("failed to run command: %s\n", pcmd);
        char cmd_output[1024];
        while (fgets(cmd_output, sizeof(cmd_output), p))
        {
            size_t cmd_output_len = strlen(cmd_output);
            output = realloc(output, output_sz += cmd_output_len);
            memcpy(output + output_of, cmd_output, cmd_output_len);
            output_of += cmd_output_len;
        }
        if (pclose(p)) err("error executing command: %s\n", pcmd);
        cmd = strstr(b, CMD_END);
        if (!cmd) err("unterminated command, expected: " CMD_END "\n");
        cmd_end = strchr(cmd, '\n');
        if (!cmd_end) break;
        o = cmd_end - b + 1; b += o; b_sz -= o;
    }
    #undef cpy
    output[output_sz - 1] = 0;

    if (strcmp(org, output))
    {
        FILE *output_file = fopen(input_filename, "wb");
        if (!output_file) err("failed to open output %s\n", input_filename);
        fwrite(output, 1, output_sz - 1, output_file);
    }
}

static void cmd_buildings(int argc, char **argv)
{
}

int main(int argc, char **argv)
{
    if (argc < 2) print_usage(stderr, EXIT_FAILURE);
    program_name = strdup(argv[0]);
    const char *program_cmd = argv[1];
    argv[1] = argv[0]; --argc; ++argv;
    if (!strcmp(program_cmd, "authpalette")) cmd_authpalette(argc, argv);
    else if (!strcmp(program_cmd, "linecol")) cmd_linecol(argc, argv);
    else if (!strcmp(program_cmd, "playfield")) cmd_playfield(argc, argv);
    else if (!strcmp(program_cmd, "scramble")) cmd_scramble(argc, argv);
    else if (!strcmp(program_cmd, "sprite")) cmd_sprite(argc, argv);
    else if (!strcmp(program_cmd, "buildings")) cmd_buildings(argc, argv);
    else if (!strcmp(program_cmd, "update")) cmd_update(argc, argv);
    else print_usage(stderr, EXIT_FAILURE);
    return EXIT_SUCCESS;
}
