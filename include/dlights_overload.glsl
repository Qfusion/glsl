#ifdef DLIGHTS_LIGHTBITS_IN
myhalf3 DynamicLightsColor(in vec4 Position, in myhalf3 surfaceNormalModelspace, in int lightBits)
#else
myhalf3 DynamicLightsColor(in vec4 Position, in myhalf3 surfaceNormalModelspace)
#endif
{
	myhalf3 Color = myhalf3(0.0);
	
#if !defined(GL_ES) && (QF_GLSL_VERSION >= 130) && defined(DLIGHTS_LIGHTBITS_IN)
	int mask = 15;
#endif

#if NUM_DLIGHTS > 4 // prevent the compiler from possibly handling the NUM_DLIGHTS <= 4 case as a real loop
#if !defined(GL_ES) && (QF_GLSL_VERSION >= 130)
	for (int dlight = 0; dlight < u_NumDynamicLights; dlight += 4)
#else
	for (int dlight = 0; dlight < NUM_DLIGHTS; dlight += 4)
#endif
#else
#define dlight 0
#endif
	{
#if !defined(GL_ES) && (QF_GLSL_VERSION >= 130) && defined(DLIGHTS_LIGHTBITS_IN)
		if ((lightBits & mask) == 0) {
#if NUM_DLIGHTS > 4
			mask = mask << 4;
			continue;
#else
			return Color;
#endif
		}

		myhalf4 bits = myhalf4(
			myhalf(((lightBits) >> (dlight+0)) & 1),
			myhalf(((lightBits) >> (dlight+1)) & 1),
			myhalf(((lightBits) >> (dlight+2)) & 1),
			myhalf(((lightBits) >> (dlight+3)) & 1));
#else
		myhalf4 bits = myhalf4(1.0);
#endif

		vec3 STR[4];
		STR[0] = vec3(u_DlightMatrix[dlight] * Position);
		STR[1] = vec3(u_DlightMatrix[dlight + 1] * Position);
		STR[2] = vec3(u_DlightMatrix[dlight + 2] * Position);
		STR[3] = vec3(u_DlightMatrix[dlight + 3] * Position);
		myhalf4 distance = myhalf4(length(STR[0]), length(STR[1]), length(STR[2]), length(STR[3]));
		myhalf4 falloff = clamp(myhalf4(1.0) - distance * u_DlightDiffuseAndInvRadius[dlight + 3], 0.0, 1.0);

		falloff *= falloff;

#if !defined(GL_ES) && (QF_GLSL_VERSION >= 130)

#if defined(APPLY_REALTIME_SHADOWS)
		for (int s = 0; s < 4; s++) {
#if !defined(GL_ES) && (QF_GLSL_VERSION >= 130) && defined(DLIGHTS_LIGHTBITS_IN)
			if (lightBits >= (1 << (dlight+s)) && ((lightBits & (1 << (dlight+s))) != 0)) {
#endif
				if (u_DlightShadowmapParams[dlight+s].z > 0) {
					vec3 shadowmaptc = GetShadowMapTC2D(STR[s], u_DlightShadowmapParams[dlight+s]) + vec3(u_DlightShadowmapTextureScale[dlight+s].zw, 0.0f);
					bits[s] *= ShadowmapFilter(u_ShadowmapTexture, shadowmaptc, u_DlightShadowmapTextureScale[dlight+s].xy);
				}
#if !defined(GL_ES) && (QF_GLSL_VERSION >= 130) && defined(DLIGHTS_LIGHTBITS_IN)
			}
#endif
		}
#endif

		falloff *= bits;
#endif

		distance = myhalf4(-1.0) / distance;
		falloff *= max(myhalf4(
			dot(myhalf3(STR[0]) * distance.xxx, surfaceNormalModelspace),
			dot(myhalf3(STR[1]) * distance.yyy, surfaceNormalModelspace),
			dot(myhalf3(STR[2]) * distance.zzz, surfaceNormalModelspace),
			dot(myhalf3(STR[3]) * distance.www, surfaceNormalModelspace)), 0.0);

		// light colors are supposed to be linear
		myhalf4 C0 = myhalf4(u_DlightDiffuseAndInvRadius[dlight]);
		myhalf4 C1 = myhalf4(u_DlightDiffuseAndInvRadius[dlight + 1]);
		myhalf4 C2 = myhalf4(u_DlightDiffuseAndInvRadius[dlight + 2]);
		Color += myhalf3(dot(C0, falloff), dot(C1, falloff), dot(C2, falloff));
		
#if !defined(GL_ES) && (QF_GLSL_VERSION >= 130) && defined(DLIGHTS_LIGHTBITS_IN)
		mask = mask << 4;
#endif
	}

	Color *= u_LightingIntensity;
	return Color;
#ifdef dlight
#undef dlight
#endif
}
