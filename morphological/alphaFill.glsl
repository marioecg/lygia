#include "../sample.glsl"
#include "../math/const.glsl"

/*
original_author: Patricio Gonzalez Vivo
description: fill alpha with edge colors
use: <vec4> fillAlpha(<sampler2D> texture, <vec2> st, <vec2> pixel, <int> passes)
options:
    - SAMPLER_FNC(TEX, UV): optional depending the target version of GLSL (texture2D(...) or texture(...))
    - ALPHAFILL_RADIUS
*/

#ifndef ALPHAFILL_RADIUS
#define ALPHAFILL_RADIUS 2.0
#endif

#ifndef FNC_ALPHAFILL
#define FNC_ALPHAFILL

vec4 alphaFill(sampler2D tex, vec2 st, vec2 pixel, int passes) {
    vec4 accum = vec4(0.0, 0.0, 0.0, 0.0);
    float max_dist = sqrt(ALPHAFILL_RADIUS * ALPHAFILL_RADIUS);
    for (int s = 0; s < passes; s++) {    
        vec2 spiral = vec2(sin(float(s)*GOLDEN_ANGLE), cos(float(s)*GOLDEN_ANGLE));
        float dist = sqrt(ALPHAFILL_RADIUS * float(s));
        spiral *= dist;
        vec4 sampled_pixel = SAMPLER_FNC(tex, st + spiral * pixel);
        sampled_pixel.rgb *= sampled_pixel.a;
        accum += sampled_pixel * (1.0 / (1.0 + dist));
        if (accum.a >= 1.0) 
            break;
    }

    return accum.rgba / max(0.0001, accum.a);
}

#endif