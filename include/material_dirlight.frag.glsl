#include_if(APPLY_CELSHADING) "material_celshading.frag.glsl"

myhalf3 DirectionalLightColor(in myhalf3 surfaceNormalModelspace, out myhalf3 weightedDiffuseNormalModelspace)
{
	myhalf3 diffuseNormalModelspace;
	myhalf3 color = myhalf3(0.0);

	diffuseNormalModelspace = u_LightDir;
	weightedDiffuseNormalModelspace = diffuseNormalModelspace;

#if defined(APPLY_CELSHADING)

	color.rgb += CelShading(surfaceNormalModelspace, diffuseNormalModelspace);

#else

	myhalf diffuseProduct = myhalf(dot(surfaceNormalModelspace, diffuseNormalModelspace));

#ifdef APPLY_HALFLAMBERT
	diffuseProduct = clamp(diffuseProduct, 0.0, 1.0) * 0.5 + 0.5;
	diffuseProduct *= diffuseProduct;
#endif // APPLY_HALFLAMBERT

	myhalf3 diffuse = LinearColor(u_LightDiffuse.rgb) * myhalf(max (diffuseProduct, 0.0)) + LinearColor(u_LightAmbient.rgb);
	color.rgb += diffuse;

#endif // APPLY_CELSHADING

	return color;
}
