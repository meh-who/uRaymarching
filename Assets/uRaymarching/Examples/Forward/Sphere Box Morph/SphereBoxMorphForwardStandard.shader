Shader "Raymarching/SphereBoxMorphForwardStandard"
{

Properties
{
    [Header(Base)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
    _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2

    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching Settings)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 10
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowExtraBias("Shadow Extra Bias", Range(0.0, 1.0)) = 0.01

// @block Properties
// _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
// @endblock
}

SubShader
{

Tags
{
    "RenderType" = "Opaque"
    "Queue" = "Geometry"
    "DisableBatching" = "True"
}

Cull [_Cull]

CGINCLUDE

#define OBJECT_SHAPE_CUBE

#define USE_RAYMARCHING_DEPTH
#define SPHERICAL_HARMONICS_PER_PIXEL
#define CAMERA_INSIDE_OBJECT

#define DISTANCE_FUNCTION DistanceFunction
#define PostEffectOutput SurfaceOutputStandard

#include "Assets/uRaymarching/Shaders/Include/Common.cginc"

// @block DistanceFunction
inline float DistanceFunction(float3 pos)
{
    float t = _Time.x;
    float a = 6 * PI * t;
    float s = pow(sin(a), 2.0);
    float d1 = Sphere(pos, 0.75);
    float d2 = RoundBox(
        Repeat(pos, 0.2),
        0.1 - 0.1 * s,
        0.1 / length(pos * 2.0));
    return lerp(d1, d2, s);
}
// @endblock

// @block PostEffectBasePass
inline void PostEffect_BasePass(RaymarchInfo ray, inout PostEffectOutput o)
{
    o.Occlusion *= pow(1.0 - 1.0 * ray.loop / ray.maxLoop, 2.0);
}
// @endblock

// @block PostEffectAddPass
inline void PostEffect_AddPass(RaymarchInfo ray, inout PostEffectOutput o)
{
    o.Occlusion *= pow(1.0 - 1.0 * ray.loop / ray.maxLoop, 2.0);
}
// @endblock

ENDCG

Pass
{
    Tags { "LightMode" = "ForwardBase" }

    ZWrite [_ZWrite]

    CGPROGRAM
    #define POST_EFFECT PostEffect_BasePass
    #include "Assets/uRaymarching/Shaders/Include/VertFragForwardObjectStandardBase.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma multi_compile_fwdbase
    ENDCG
}

Pass
{
    Tags { "LightMode" = "ForwardAdd" }
    ZWrite Off 
    Blend One One

    CGPROGRAM
    #define POST_EFFECT PostEffect_AddPass
    #include "Assets/uRaymarching/Shaders/Include/VertFragForwardObjectStandardAdd.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma skip_variants INSTANCING_ON
    #pragma multi_compile_fwdadd_fullshadows
    ENDCG
}

Pass
{
    Tags { "LightMode" = "ShadowCaster" }

    CGPROGRAM
    #include "Assets/uRaymarching/Shaders/Include/VertFragShadowObject.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma fragmentoption ARB_precision_hint_fastest
    #pragma multi_compile_shadowcaster
    ENDCG
}

}

Fallback Off

CustomEditor "uShaderTemplate.MaterialEditor"

}