uniform mat4 u_ModelViewMatrix;
uniform mat4 u_ModelViewProjectionMatrix;

uniform float u_ShaderTime;

uniform vec3 u_ViewOrigin;
uniform mat3 u_ViewAxis;

uniform vec3 u_EntityDist;
uniform vec3 u_EntityOrigin;
uniform myhalf4 u_EntityColor;

#ifdef NUM_LIGHTMAPS
uniform myhalf3 u_LightstyleColor[NUM_LIGHTMAPS];
#endif

uniform myhalf3 u_LightAmbient;
uniform myhalf3 u_LightDiffuse;
uniform vec3 u_LightDir;
uniform myhalf u_LightingIntensity;

uniform myhalf2 u_BlendMix;

uniform myhalf u_ColorMod;

uniform vec4 u_TextureMatrix[2];
#define TextureMatrix2x3Mul(m2x3,tc) (vec2(dot((m2x3)[0].xy, (tc)), dot((m2x3)[0].zw, (tc))) + (m2x3)[1].xy)

uniform float u_MirrorSide;

uniform vec2 u_ZRange;

uniform ivec4 u_Viewport; // x, y, width, height

uniform vec4 u_TextureParams;

#if defined(NUM_DLIGHTS)

uniform mat4 u_DlightMatrix[NUM_DLIGHTS];
uniform myhalf4 u_DlightDiffuseAndInvRadius[NUM_DLIGHTS];

#if !defined(GL_ES) && (QF_GLSL_VERSION >= 130)
uniform int u_NumDynamicLights;
#endif

#if defined(APPLY_LIGHTBITS) && !defined(GL_ES) && (QF_GLSL_VERSION >= 130)
uniform int u_LightBits[MAX_DRAWSURF_SURFS];
#endif // APPLY_LIGHTBITS

#ifdef APPLY_REALTIME_SHADOWS
uniform vec4 u_DlightShadowmapParams[NUM_DLIGHTS];
uniform vec4 u_DlightShadowmapTextureScale[NUM_DLIGHTS];
#endif // APPLY_REALTIME_SHADOWS


#endif
