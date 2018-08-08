#ifdef APPLY_SHADOW_SAMPLERS
# define SHADOW_SAMPLER sampler2DShadow
#else
# define SHADOW_SAMPLER sampler2D
#endif

uniform mat4 u_ModelViewMatrix;
uniform mat4 u_ModelViewProjectionMatrix;

uniform float u_ShaderTime;

uniform vec3 u_ViewOrigin;
uniform mat3 u_ViewAxis;

uniform vec3 u_EntityDist;
uniform vec3 u_EntityOrigin;
uniform myhalf4 u_EntityColor;

#if defined(NUM_LIGHTMAPS)
uniform myhalf3 u_LightstyleColor[NUM_LIGHTMAPS];
#elif defined(APPLY_VERTEX_LIGHTING)
uniform myhalf3 u_LightstyleColor[1];
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

#if defined(APPLY_REALTIME_SHADOWS) || defined(APPLY_DLIGHT_CUBEFILTER)
uniform mat4 u_DlightMatrix;
#endif
uniform vec3 u_DlightVector;

uniform myhalf4 u_DlightDiffuseAndInvRadius;

#ifdef APPLY_DLIGHT_CUBEFILTER
uniform samplerCube u_CubeFilter;
#endif

#ifdef APPLY_REALTIME_SHADOWS
uniform SHADOW_SAMPLER u_ShadowmapTexture;

uniform vec4 u_ShadowmapParams;
uniform vec4 u_ShadowmapTextureScale;

uniform int u_ShadowmapNumCascades;
uniform mat4 u_ShadowmapCascadeMatrix[MAX_SHADOW_CASCADES];
uniform float u_ShadowmapCascadesBlendArea;

#endif // APPLY_REALTIME_SHADOWS


#endif
