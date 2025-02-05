#include "../color/tonemap.glsl"

#include "material.glsl"
#include "light/new.glsl"
#include "ior.glsl"
#include "envMap.glsl"
#include "specular.glsl"
#include "fresnelReflection.glsl"

#include "ior/2eta.glsl"
#include "ior/2f0.glsl"

#include "reflection.glsl"
#include "common/specularAO.glsl"
#include "common/envBRDFApprox.glsl"

/*
contributors: Patricio Gonzalez Vivo
description: simple glass shading model
use: 
    - <vec4> glass(<Material> material) 
    
options:
    - SPECULAR_FNC: specularGaussian, specularBeckmann, specularCookTorrance (default), specularPhongRoughness, specularBlinnPhongRoughnes (default on mobile)
    - SCENE_BACK_SURFACE: 
    - LIGHT_POSITION: in GlslViewer is u_light
    - LIGHT_DIRECTION: 
    - LIGHT_COLOR in GlslViewer is u_lightColor
    - CAMERA_POSITION: in GlslViewer is u_camera
examples:
    - /shaders/lighting_raymarching_glass.frag
*/

#ifndef IBL_LUMINANCE
#define IBL_LUMINANCE   1.0
#endif

#ifndef FNC_PBRGLASS
#define FNC_PBRGLASS

vec4 pbrGlass(const Material _mat) {
    
    // Cached
    Material M  = _mat;
    M.V         = normalize(CAMERA_POSITION - M.position);  // View
    M.NoV       = dot(M.normal, M.V);                       // Normal . View
    M.R         = reflection(M.V, M.normal, M.roughness);   // Reflection

    vec3    Nf      = M.normal;                                  // Normal front
    vec3    No      = M.normal;                                  // Normal out
#if defined(SCENE_BACK_SURFACE)
            No      = normalize(Nf - M.normal_back);
#endif

    vec3    f0      = ior2f0(M.ior);
    vec3    eta     = ior2eta(M.ior);
    vec3    RaG     = refract(-M.V, No, eta.g);
    #if !defined(TARGET_MOBILE) && !defined(PLATFORM_RPI)
    vec3    RaR     = refract(-M.V, No, eta.r);
    vec3    RaB     = refract(-M.V, No, eta.b);
    #endif

    // Global Ilumination ( mage Based Lighting )
    // ------------------------
    vec3 E = envBRDFApprox(M.albedo.rgb, M);

    vec3 Fr = vec3(0.0, 0.0, 0.0);
    Fr  = envMap(M) * E;
    #if !defined(PLATFORM_RPI)
    Fr  += tonemap( fresnelReflection(M) ) * (1.0-M.roughness) * 0.2;
    #endif

    vec4 color  = vec4(0.0, 0.0, 0.0, 1.0);
    color.rgb   = envMap(RaG, M.roughness);
    #if !defined(TARGET_MOBILE) && !defined(PLATFORM_RPI)
    color.r     = envMap(RaR, M.roughness).r;
    color.b     = envMap(RaB, M.roughness).b;
    #endif
    // color.rgb   *= exp( -M.thickness * 200.0);
    color.rgb   += Fr * IBL_LUMINANCE;

    // TODO: 
    //  - Add support for multiple lights
    // 
    {
        #if defined(LIGHT_DIRECTION)
        LightDirectional L = LightDirectionalNew();
        #elif defined(LIGHT_POSITION)
        LightPoint L = LightPointNew();
        #endif

        #if defined(LIGHT_DIRECTION) || defined(LIGHT_POSITION)
        // lightResolve(diffuseColor, specularColor, M, L, lightDiffuse, lightSpecular);
        color.rgb += L.color * specular(L.direction, M.normal, M.V, M.roughness);
        #endif
    }

    return color;
}



#endif