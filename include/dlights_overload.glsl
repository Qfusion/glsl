myhalf3 DynamicLightsColor(in vec4 Position, in myhalf3 surfaceNormalModelspace)
{
	myhalf3 Color = myhalf3(u_DlightDiffuseAndInvRadius.xyz);

	myhalf3 dir = myhalf3(u_DlightVector - Position.xyz);
	myhalf distance = myhalf(length(dir));

	myhalf falloff = clamp(myhalf(1.0) - distance * u_DlightDiffuseAndInvRadius.w, 0.0, 1.0);
	falloff *= falloff;

#if defined(APPLY_REALTIME_SHADOWS) || defined(APPLY_DLIGHT_CUBEFILTER)
	vec3 cubeVec = vec3(u_DlightMatrix * Position);
#endif

#ifdef APPLY_REALTIME_SHADOWS
	vec3 shadowmaptc = GetShadowMapTC2D(cubeVec, u_DlightShadowmapParams) + vec3(u_DlightShadowmapTextureScale.zw, 0.0f);
	falloff *= ShadowmapFilter(u_ShadowmapTexture, shadowmaptc, u_DlightShadowmapTextureScale.xy);
#endif

	distance = myhalf(1.0) / distance;
	falloff *= max(myhalf(dot(dir * distance, surfaceNormalModelspace)), 0.0);

	Color *= falloff;

#ifdef APPLY_DLIGHT_CUBEFILTER
	Color *= myhalf3(qf_textureCube(u_CubeFilter, cubeVec));
#endif

	return Color;
}
