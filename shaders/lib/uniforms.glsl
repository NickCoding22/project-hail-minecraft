// Shared uniforms (Iris / OptiFine). Declared in each stage that uses them.
#ifndef PHM_UNIFORMS_GLSL
#define PHM_UNIFORMS_GLSL

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform vec3 sunPosition;
uniform vec3 fogColor;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform int biome_category;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;

#ifdef IRIS
uniform bool hasSkylight;
uniform bool hasCeiling;
#endif

#endif // PHM_UNIFORMS_GLSL
