// (hookshot-rog-ally, issue 4) The held fallback draws' ranges of the records buffer (RX_VK_FALLBACK_BATCH): fb_config and
// fb_header cut from gpu/vk/vk_draw.cpp (tests/test_fallback_batch.py), checked for every record size a program can have
// and for draws of different programs side by side: each draw's header and records inside the buffer, no draw's records over
// another's or over any header, and each draw given the room it was promised.
#include <algorithm>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>

namespace Shader::Backend::SPIRV {
constexpr uint32_t MESH_FALLBACK_HEADER_WORDS = 8;
constexpr uint32_t MESH_FALLBACK_RECORD_WORDS = 16u << 20;
}
struct Program { uint32_t fallback_record_words = 1; };
static void logf(const char*, ...) {}

#include "fallback_batch_actual.inc"

namespace {
int failures = 0;
void fail(const char* what, uint32_t a, uint32_t b, int k, int j) {
    if (failures++ < 20) std::printf("FAIL: %s (words %u and %u, draws %d and %d)\n", what, a, b, k, j);
}
struct Span { uint64_t lo, hi; };
bool overlap(Span x, Span y) { return x.lo < y.hi && y.lo < x.hi; }
}

int main(int argc, char** argv) {
    if (argc < 3) return 2;
    const FbConfig& c = fb_config();
    const int want_draws = std::atoi(argv[1]), want_compact = std::atoi(argv[2]);
    if (c.draws != want_draws) {
        std::printf("FAIL: %d draws held, %d expected\n", c.draws, want_draws);
        return 1;
    }
    if (!c.draws) {
        std::printf("off, as expected\n");
        return 0;
    }
    if ((int)c.compact != want_compact) {
        std::printf("FAIL: compact %d, %d expected\n", (int)c.compact, want_compact);
        return 1;
    }
    constexpr uint64_t header = Shader::Backend::SPIRV::MESH_FALLBACK_HEADER_WORDS * 4;
    std::vector<uint32_t> sizes;   // (a program's record words: every one up to the batch's limit of 16 KB a record)
    for (uint32_t w = 1; w * 4 <= 16384; w += w < 128 ? 1 : 37) sizes.push_back(w);
    sizes.push_back(4096);
    const auto records = [&](uint32_t words, int k) {
        Program p;
        p.fallback_record_words = words;
        const FbHeader h = fb_header(p, k);
        const uint32_t fit = Shader::Backend::SPIRV::MESH_FALLBACK_RECORD_WORDS / words;
        return Span{h.offset + header + (uint64_t)h.start * words * 4, h.offset + header + (uint64_t)fit * words * 4};
    };
    const auto head = [&](uint32_t words, int k) {
        Program p;
        p.fallback_record_words = words;
        const uint64_t at = fb_header(p, k).offset;
        return Span{at, at + header};
    };
    for (uint32_t a : sizes) {
        for (int k = 0; k < c.draws; k++) {
            const Span r = records(a, k), h = head(a, k);
            if (h.lo % 4) fail("a header not on a word", a, a, k, k);
            if (r.hi > c.records_bytes || h.hi > c.records_bytes) fail("past the buffer", a, a, k, k);
            const uint64_t room = std::min<uint64_t>(c.room, (uint64_t)(Shader::Backend::SPIRV::MESH_FALLBACK_RECORD_WORDS / a) * a * 4);
            if (r.hi - r.lo + (uint64_t)a * 4 <= room) fail("less room than promised", a, a, k, k);
            if (overlap(r, h)) fail("records over the draw's own header", a, a, k, k);
        }
    }
    // (draws of different programs held together: a few sizes against each other, every pair of slots)
    const uint32_t mix[] = {1, 2, 3, 7, 9, 13, 31, 32, 33, 64, 100, 255, 1000, 4096};
    for (uint32_t a : mix)
        for (uint32_t b : mix)
            for (int k = 0; k < c.draws; k++)
                for (int j = 0; j < c.draws; j++) {
                    if (k == j) continue;
                    if (overlap(records(a, k), records(b, j))) fail("two draws' records overlap", a, b, k, j);
                    if (overlap(records(a, k), head(b, j))) fail("a draw's records over another's header", a, b, k, j);
                    if (overlap(head(a, k), head(b, j))) fail("two headers overlap", a, b, k, j);
                }
    std::printf("%d draws, %s, records %llu MB a draw, buffer %llu MB: %s\n", c.draws, c.compact ? "compact" : "full areas",
                (unsigned long long)(c.room >> 20), (unsigned long long)(c.records_bytes >> 20), failures ? "FAILED" : "ok");
    return failures ? 1 : 0;
}
