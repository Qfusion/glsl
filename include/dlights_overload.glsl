#ifdef DLIGHTS_LIGHTBITS_IN
myhalf3 DynamicLightsColor(in vec3 Position, in myhalf3 surfaceNormalModelspace, int lightBits)
#else
myhalf3 DynamicLightsColor(in vec3 Position, in myhalf3 surfaceNormalModelspace)
#endif
{
	myhalf3 Color = myhalf3(0.0);

#if NUM_DLIGHTS > 4 // prevent the compiler from possibly handling the NUM_DLIGHTS <= 4 case as a real loop
#if !defined(GL_ES) && (QF_GLSL_VERSION >= 330)
	for (int dlight = 0; dlight < u_NumDynamicLights; dlight += 4)
#else
	for (int dlight = 0; dlight < NUM_DLIGHTS; dlight += 4)
#endif
#else
#define dlight 0
#endif
	{
#if !defined(GL_ES) && (QF_GLSL_VERSION >= 330) && defined(DLIGHTS_LIGHTBITS_IN)
		int bit0 = 1 << dlight, bit1 = 1 << (dlight+1), bit2 = 1 << (dlight+2), bit3 = 1 << (dlight+3);
		int l0 = (lightBits & bit0) / bit0, l1 = (lightBits & bit1) / bit1, l2 = (lightBits & bit2) / bit2, l3 = (lightBits & bit3) / bit3;
		myhalf4 bits = myhalf4(myhalf(l0), myhalf(l1), myhalf(l2), myhalf(l3));

		if( l0 == 0 && l1 == 0 && l2 == 0 && l3 == 0 )
#if NUM_DLIGHTS > 4
			continue;
#else
			return Color;
#endif
#endif

		myhalf3 STR0 = myhalf3(u_DlightPosition[dlight] - Position);
		myhalf3 STR1 = myhalf3(u_DlightPosition[dlight + 1] - Position);
		myhalf3 STR2 = myhalf3(u_DlightPosition[dlight + 2] - Position);
		myhalf3 STR3 = myhalf3(u_DlightPosition[dlight + 3] - Position);
		myhalf4 distance = myhalf4(length(STR0), length(STR1), length(STR2), length(STR3));
		myhalf4 falloff = clamp(myhalf4(1.0) - distance * u_DlightDiffuseAndInvRadius[dlight + 3], 0.0, 1.0);

		falloff *= falloff;

#if !defined(GL_ES) && (QF_GLSL_VERSION >= 330) && defined(DLIGHTS_LIGHTBITS_IN)
		falloff *= bits;
#endif

		distance = myhalf4(1.0) / distance;
		falloff *= max(myhalf4(
			dot(STR0 * distance.xxx, surfaceNormalModelspace),
			dot(STR1 * distance.yyy, surfaceNormalModelspace),
			dot(STR2 * distance.zzz, surfaceNormalModelspace),
			dot(STR3 * distance.www, surfaceNormalModelspace)), 0.0);

		// light colors are supposed to be linear
		myhalf4 C0 = myhalf4(u_DlightDiffuseAndInvRadius[dlight]);
		myhalf4 C1 = myhalf4(u_DlightDiffuseAndInvRadius[dlight + 1]);
		myhalf4 C2 = myhalf4(u_DlightDiffuseAndInvRadius[dlight + 2]);
		Color += myhalf3(dot(C0, falloff), dot(C1, falloff), dot(C2, falloff));
	}

	Color *= u_LightingIntensity;
	return Color;
#ifdef dlight
#undef dlight
#endif
}
