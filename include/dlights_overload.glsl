myhalf3 DynamicLightsColor(in vec4 Position, in myhalf3 surfaceNormalModelspace)
{
	myhalf3 dir;
	myhalf3 Color = myhalf3(u_DlightDiffuseAndInvRadius.xyz);
	vec3 cubeVec;

#if defined(APPLY_DLIGHT_DIRECTIONAL)
	dir = myhalf3(u_DlightVector);
#else
	dir = myhalf3(u_DlightVector - Position.xyz);
#endif

	myhalf scale = myhalf(dot(dir, surfaceNormalModelspace));
	if( scale <= 0.0f ) {
		discard;
	}

#if !defined(APPLY_DLIGHT_DIRECTIONAL)
	myhalf dist = myhalf(length(dir));
	myhalf falloff = myhalf(1.0) - dist * u_DlightDiffuseAndInvRadius.w;

	falloff = clamp(falloff, 0.0, 1.0);
	falloff *= falloff;

	scale *= myhalf(1.0) / dist; // norm the dot product with surface normal
	scale *= falloff;
#endif

#ifdef APPLY_REALTIME_SHADOWS
	myhalf shadow;
	vec3 shadowmaptc;

#ifdef APPLY_DLIGHT_DIRECTIONAL
	if (u_ShadowmapNumCascades > 1) {
		shadow = ShadowmapOrthoFilterCSM(u_ShadowmapTexture, u_ShadowmapNumCascades, u_ShadowmapCascadeMatrix, Position, Color, u_ShadowmapTextureScale, u_ShadowmapParams);
	} else {
		shadow = ShadowmapOrthoFilter(u_ShadowmapTexture, u_ShadowmapCascadeMatrix[0], Position, u_ShadowmapTextureScale, u_ShadowmapParams);
	}
#else
	cubeVec = vec3(u_DlightMatrix * Position);
	shadowmaptc = GetShadowMapTC2D(cubeVec, u_ShadowmapParams);
	shadow = ShadowmapFilter(u_ShadowmapTexture, shadowmaptc + vec3(u_ShadowmapTextureScale.zw, 0.0f), u_ShadowmapTextureScale.xy);
#endif

	scale *= shadow;
#else

#ifdef APPLY_DLIGHT_CUBEFILTER
	cubeVec = vec3(u_DlightMatrix * Position);
#endif

#endif

	Color *= scale;

#ifdef APPLY_DLIGHT_CUBEFILTER
	Color *= myhalf3(qf_textureCube(u_CubeFilter, cubeVec));
#endif

	return Color;
}
