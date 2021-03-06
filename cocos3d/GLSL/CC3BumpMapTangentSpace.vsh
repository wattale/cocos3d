/*
 * CC3BumpMapTangentSpace.vsh
 *
 * cocos3d 2.0.0
 * Author: Bill Hollings
 * Copyright (c) 2011-2013 The Brenwill Workshop Ltd. All rights reserved.
 * http://www.brenwill.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * http://en.wikipedia.org/wiki/MIT_License
 */

/**
 * This vertex shader performs tangent-space bump-mapping.
 *
 * The texture in texture unit 0 contains a map of tangent-space normals, encoded in the
 * texel RGB colors.
 *
 * An optional second texture in texture unit 1 contains the visible texture to be applied on
 * top of the bump-mapped texture. If this texture is not available, the fragment color is used.
 *
 * CC3BumpMapTangentSpace.fsh or CC3BumpMapTangentSpaceWithAlphaTest.fsh are the fragment shaders
 * that can be paired with this vertex shader.
 *
 * The semantics of the variables in this shader can be mapped using a
 * CC3GLProgramSemanticsByVarName instance.
 */

// Increase these if more textures or lights are desired.
#define MAX_TEXTURES			2
#define MAX_LIGHTS				4

// Maximum bones per skin section (batch).
#define MAX_BONES_PER_VERTEX	11

precision mediump float;


//-------------- STRUCTURES ----------------------

/**
 * The various transform matrices.
 *
 * When using this structure as the basis of a simpler implementation, you can comment-out
 * or remove any elements that are not used by either your vertex or fragment shaders, to
 * reduce the number of values that need to be retrieved and passed to your shader.
 */
struct Matrices {
//	highp mat4	modelLocal;				/**< Current model-to-parent matrix. */
//	mat4		modelLocalInv;			/**< Inverse of current model-to-parent matrix. */
//	mat3		modelLocalInvTran;		/**< Inverse-transpose of current model-to-parent rotation matrix. */
	
//	highp mat4	model;					/**< Current model-to-world matrix. */
//	mat4		modelInv;				/**< Inverse of current model-to-world matrix. */
//	mat3		modelInvTran;			/**< Inverse-transpose of current model-to-world rotation matrix. */
	
//	highp mat4	view;					/**< Camera view matrix. */
//	mat4		viewInv;				/**< Inverse of camera view matrix. */
//	mat3		viewInvTran;			/**< Inverse-transpose of camera view rotation matrix. */
	
	highp mat4	modelView;				/**< Current modelview matrix. */
//	mat4		modelViewInv;			/**< Inverse of current modelview matrix. */
	mat3		modelViewInvTran;		/**< Inverse-transpose of current modelview rotation matrix. */
	
	highp mat4	proj;					/**< Projection matrix. */
//	mat4		projInv;				/**< Inverse of projection matrix. */
//	mat3		projInvTran;			/**< Inverse-transpose of projection rotation matrix. */
	
//	highp mat4	viewProj;				/**< Camera view and projection matrix. */
//	mat4		viewProjInv;			/**< Inverse of camera view and projection matrix. */
//	mat3		viewProjInvTran;		/**< Inverse-transpose of camera view and projection rotation matrix. */
	
//	highp mat4	modelViewProj;			/**< Current modelview-projection matrix. */
//	mat4		modelViewProjInv;		/**< Inverse of current modelview-projection matrix. */
//	mat3		modelViewProjInvTran;	/**< Inverse-transpose of current modelview-projection rotation matrix. */
};

/**
 * The parameters to use when deforming vertices using bones.
 *
 * When using this structure as the basis of a simpler implementation, you can comment-out
 * or remove any elements that are not used by either your vertex or fragment shaders, to
 * reduce the number of values that need to be retrieved and passed to your shader.
 */
struct Bones {
	lowp int	bonesPerVertex;									/**< Number of bones influencing each vertex. */
	highp mat4	matricesEyeSpace[MAX_BONES_PER_VERTEX];			/**< Array of bone matrices in the current mesh skin section in eye space. */
	mat3		matricesInvTranEyeSpace[MAX_BONES_PER_VERTEX];	/**< Array of inverse-transposes of the bone matrices in the current mesh skin section in eye space. */
//	highp mat4	matricesGlobal[MAX_BONES_PER_VERTEX];			/**< Array of bone matrices in the current mesh skin section in global coordinates. */
//	mat3		matricesInvTranGlobal[MAX_BONES_PER_VERTEX];	/**< Array of inverse-transposes of the bone matrices in the current mesh skin section in global coordinates. */
};

/**
 * The parameters that define the material covering this vertex.
 *
 * When using this structure as the basis of a simpler implementation, you can comment-out
 * or remove any elements that are not used by either your vertex or fragment shaders, to
 * reduce the number of values that need to be retrieved and passed to your shader.
 */
struct Material {
	vec4	ambientColor;						/**< Ambient color of the material. */
	vec4	diffuseColor;						/**< Diffuse color of the material. */
	vec4	specularColor;						/**< Specular color of the material. */
	vec4	emissionColor;						/**< Emission color of the material. */
	float	shininess;							/**< Shininess of the material. */
	float	minimumDrawnAlpha;					/**< Minimum alpha value to be drawn, otherwise fragment will be discarded. */
};

/**
 * The parameters that define the lighting.
 *
 * Many of the elements in this structure is an array containing the value of that element for each
 * light. This structure-of-arrays organization is much more efficient than the alternate of defining
 * the structure to hold the values for a single light and then assembling an array-of-structures.
 * The reason is because under GLSL, the compiler creates a distinct uniform for each element in
 * each structure. The result is that an array-of-structures requires a much larger number of
 * compiled uniforms than the corresponding structure-of-arrays.
 *
 * When using this structure as the basis of a simpler implementation, you can comment-out
 * or remove any elements that are not used by either your vertex or fragment shaders, to
 * reduce the number of values that need to be retrieved and passed to your shader.
 */
struct Lighting {
	bool		isUsingLighting;					/**< Indicates whether any lighting is enabled */
	lowp vec4	sceneAmbientLightColor;				/**< Ambient light color of the scene. */
	bool		isLightEnabled[MAX_LIGHTS];			/**< Indicates whether each light is enabled. */
	vec4		positionEyeSpace[MAX_LIGHTS];		/**< Position or normalized direction in eye space of each light. */
	vec4		positionModel[MAX_LIGHTS];			/**< Position or normalized direction in the local coords of the model of each light. */
	lowp vec4	ambientColor[MAX_LIGHTS];			/**< Ambient color of each light. */
	lowp vec4	diffuseColor[MAX_LIGHTS];			/**< Diffuse color of each light. */
	lowp vec4	specularColor[MAX_LIGHTS];			/**< Specular color of each light. */
	vec3		attenuation[MAX_LIGHTS];			/**< Coefficients of the attenuation equation of each light. */
	vec3		spotDirectionEyeSpace[MAX_LIGHTS];	/**< Direction of spotlight in eye space of each light. */
	float		spotExponent[MAX_LIGHTS];			/**< Directional attenuation factor, if spotlight, of each light. */
	float		spotCutoffAngleCosine[MAX_LIGHTS];	/**< Cosine of spotlight cutoff angle of each light. */
};

/**
 * Vertex state. This contains info about the vertex, other than vertex attributes.
 *
 * When using this structure as the basis of a simpler implementation, you can comment-out
 * or remove any elements that are not used by either your vertex or fragment shaders, to
 * reduce the number of values that need to be retrieved and passed to your shader.
 */
struct VertexState {
	bool hasVertexNormal;		/**< Whether the vertex normal is available. */
	bool hasVertexTangent;		/**< Whether the vertex tangent is available. */
//	bool hasVertexBitangent;	/**< Whether the vertex bitangent is available. */
	bool hasVertexColor;		/**< Whether the vertex color is available. */
//	bool hasVertexWeight;		/**< Whether the vertex weight is available. */
//	bool hasVertexMatrixIndex;	/**< Whether the vertex matrix index is available. */
//	bool hasVertexTexCoord;		/**< Whether the vertex texture coordinate is available. */
//	bool hasVertexPointSize;	/**< Whether the vertex point size is available. */
//	bool isDrawingPoints;		/**< Whether the vertices are being drawn as points. */
	bool shouldNormalizeNormal;	/**< Whether the vertex normal should be normalized. */
	bool shouldRescaleNormal;	/**< Whether the vertex normal should be rescaled. */
};


//-------------- UNIFORMS ----------------------

uniform Matrices u_cc3Matrices;			/**< The transform matrices. */
uniform vec4 u_cc3Color;				/**< Color when lighting & materials are not in use. */
uniform Material u_cc3Material;			/**< The material being applied to the mesh. */
uniform Lighting u_cc3Lighting;			/**< Lighting configuration. */
uniform Bones u_cc3Bones;				/**< Bone transforms. */
uniform VertexState u_cc3Vertex;		/**< The vertex state (excluding vertex attributes). */
uniform lowp int u_cc3TextureCount;		/**< Number of textures. */


//-------------- VERTEX ATTRIBUTES ----------------------
attribute highp vec4 a_cc3Position;		/**< Vertex position. */
attribute vec3 a_cc3Normal;				/**< Vertex normal. */
attribute vec3 a_cc3Tangent;			/**< Vertex tangent. */
attribute vec4 a_cc3Color;				/**< Vertex color. */
attribute vec4 a_cc3BoneWeights;		/**< Vertex skinning bone weights (up to 4). */
attribute vec4 a_cc3BoneIndices;		/**< Vertex skinning bone matrix indices (up to 4). */
attribute vec2 a_cc3TexCoord0;			/**< Vertex texture coordinate for texture unit 0. */
attribute vec2 a_cc3TexCoord1;			/**< Vertex texture coordinate for texture unit 1. */
attribute vec2 a_cc3TexCoord2;			/**< Vertex texture coordinate for texture unit 2. */
attribute vec2 a_cc3TexCoord3;			/**< Vertex texture coordinate for texture unit 3. */

//-------------- VARYING VARIABLE OUTPUTS ----------------------
varying vec2 v_texCoord[MAX_TEXTURES];		/**< Fragment texture coordinates. */
//varying vec2 v_texCoord0;		/**< Fragment texture coordinates. */
//varying vec2 v_texCoord1;		/**< Fragment texture coordinates. */

varying lowp vec4 v_color;					/**< Fragment base color. */
varying highp float v_distEye;				/**< Fragment distance in eye coordinates. */
varying vec3 v_bumpMapLightDir;				/**< Direction to the first light in either tangent space or model space. */

//-------------- CONSTANTS ----------------------
const vec3 kVec3Zero = vec3(0.0);
const vec4 kVec4Zero = vec4(0.0);
const vec3 kAttenuationNone = vec3(1.0, 0.0, 0.0);
const vec3 kHalfPlaneOffset = vec3(0.0, 0.0, 1.0);

//-------------- LOCAL VARIABLES ----------------------
highp vec4 vtxPosEye;		/**< The vertex position in eye coordinates. High prec to match vertex attribute. */
vec3 vtxNormEye;			/**< The vertex normal in eye coordinates. */
vec4 matColorAmbient;		/**< Ambient color of material...from either material or vertex colors. */
vec4 matColorDiffuse;		/**< Diffuse color of material...from either material or vertex colors. */


//-------------- FUNCTIONS ----------------------

/** 
 * Transforms the vertex position and normal to eye space. Sets the vtxPosEye and vtxNormEye
 * variables. This function takes into consideration vertex skinning, if it is specified.
 */
void vertexToEyeSpace() {
	if (u_cc3Bones.bonesPerVertex > 0) {		// Mesh is bone-rigged for vertex skinning
		// Copies of the indices and weights attibutes so they can be "rotated"
		mediump ivec4 boneIndices = ivec4(a_cc3BoneIndices);
		mediump vec4 boneWeights = a_cc3BoneWeights;

		vtxPosEye = kVec4Zero;					// Start at zero to accumulate weighted values
		vtxNormEye = vec3(0.0);
		for (lowp int i = 0; i < 4; ++i) {		// Max 4 bones per vertex
			if (i < u_cc3Bones.bonesPerVertex) {
				// Add position and normal contribution from this bone
				vtxPosEye += u_cc3Bones.matricesEyeSpace[boneIndices.x] * a_cc3Position * boneWeights.x;
				vtxNormEye += u_cc3Bones.matricesInvTranEyeSpace[boneIndices.x] * a_cc3Normal * boneWeights.x;
				
				// "Rotate" the vector components to the next vertex bone index
				boneIndices = boneIndices.yzwx;
				boneWeights = boneWeights.yzwx;
			}
		}
	} else {		// No vertex skinning
		vtxPosEye = u_cc3Matrices.modelView * a_cc3Position;
		vtxNormEye = u_cc3Matrices.modelViewInvTran * a_cc3Normal;
	}
}

/** 
 * Returns the portion of vertex color attributed to illumination of the material by the light at the
 * specified index, taking into consideration attenuation due to distance and spotlight dispersion.
 *
 * The use of highp on the floats is required due to the sensitivity of the calculations.
 * Compiler can crash when attempting to cast back and forth.
 */
vec4 illuminateWith(int ltIdx) {
	highp vec3 ltDir;
	highp float intensity = 1.0;
	
	if (u_cc3Lighting.positionEyeSpace[ltIdx].w != 0.0) {
		// Positional light. Find the direction from vertex to light.
		ltDir = (u_cc3Lighting.positionEyeSpace[ltIdx] - vtxPosEye).xyz;
		
		// Calculate intensity due to distance attenuation (must be performed in high precision)
		if (u_cc3Lighting.attenuation[ltIdx] != kAttenuationNone) {
			highp float ltDist = length(ltDir);
			highp vec3 distAtten = vec3(1.0, ltDist, ltDist * ltDist);
			highp float distIntensity = 1.0 / dot(distAtten, u_cc3Lighting.attenuation[ltIdx]);	// needs highp
			intensity *= min(abs(distIntensity), 1.0);
		}
		ltDir = normalize(ltDir);
		
		// Determine intensity due to spotlight component
		highp float spotCutoffCos = u_cc3Lighting.spotCutoffAngleCosine[ltIdx];
		if (spotCutoffCos >= 0.0) {
			highp vec3  spotDirEye = u_cc3Lighting.spotDirectionEyeSpace[ltIdx];
			highp float cosEyeDir = -dot(ltDir, spotDirEye);
			if (cosEyeDir >= spotCutoffCos){
				highp float spotExp = u_cc3Lighting.spotExponent[ltIdx];
				intensity *= pow(cosEyeDir, spotExp);
			} else {
				intensity = 0.0;
			}
		}
    } else {
		// Directional light. Vector is expected to be normalized!
		ltDir = u_cc3Lighting.positionEyeSpace[ltIdx].xyz;
    }
	
	// If no light intensity, short-circuit and return no color
	if (intensity <= 0.0) return kVec4Zero;
	
	// Employ lighting equation to calculate vertex color
	vec4 vtxColor = (u_cc3Lighting.ambientColor[ltIdx] * matColorAmbient);
	vtxColor += (u_cc3Lighting.diffuseColor[ltIdx] * matColorDiffuse * max(0.0, dot(vtxNormEye, ltDir)));
	
	// Project normal onto half-plane vector to determine specular component
	float specProj = dot(vtxNormEye, normalize(ltDir + kHalfPlaneOffset));
	if (specProj > 0.0) {
		vtxColor += (pow(specProj, u_cc3Material.shininess) *
					 u_cc3Material.specularColor *
					 u_cc3Lighting.specularColor[ltIdx]);
	}

	// Return the attenuated vertex color
	return vtxColor * intensity;
}

/**
 * Returns the direction to the specified light in tangent space coordinates.
 * The associated normal-map texture must match this and specify its normals in tangent-space.
 */
vec3 bumpMapDirectionForLight(int ltIdx) {

	// Get the light direction in model space. If the light is positional
	// calculate the normalized direction from the light and vertex positions.
	vec3 ltDir;
	vec4 ltPos = u_cc3Lighting.positionModel[ltIdx];
	if (ltPos.w == 0.0)
		ltDir = ltPos.xyz;									// Directional
	else
		ltDir = normalize(ltPos.xyz - a_cc3Position.xyz);	// Positional
		
	// If we have vertex tangents, create a matrix that transforms from model space to tangent space,
	// and transform the light direction to tangent space. If no tangents, leave in model-space.
	if (u_cc3Vertex.hasVertexTangent) {
		vec3 bitangent = cross(a_cc3Normal, a_cc3Tangent);
		mat3 tangentSpaceXfm = mat3(a_cc3Tangent, bitangent, a_cc3Normal);
		ltDir *= tangentSpaceXfm;
	}

	return ltDir;
}

/**
 * Returns the vertex color by starting with material emission and ambient scene lighting,
 * and then illuminating the material with each enabled light.
 */
vec4 illuminate() {
	vec4 vtxColor = u_cc3Material.emissionColor + (matColorAmbient * u_cc3Lighting.sceneAmbientLightColor);

	for (int ltIdx = 0; ltIdx < MAX_LIGHTS; ltIdx++)
		if (u_cc3Lighting.isLightEnabled[ltIdx]) vtxColor += illuminateWith(ltIdx);
	
	vtxColor.a = matColorDiffuse.a;
	
	// If the model uses bump-mapping, we need a variable to track the light direction.
	// It's a varying because when using tangent-space normals, we need the light direction per fragment.
	v_bumpMapLightDir = bumpMapDirectionForLight(0);
	
	return vtxColor;
}

//-------------- ENTRY POINT ----------------------
void main() {

	// If vertices have individual colors, use them for ambient and diffuse material colors.
	matColorAmbient = u_cc3Vertex.hasVertexColor ? a_cc3Color : u_cc3Material.ambientColor;
	matColorDiffuse = u_cc3Vertex.hasVertexColor ? a_cc3Color : u_cc3Material.diffuseColor;

	// Transform vertex position and normal to eye space, in vtxPosEye and vtxNormEye, respectively,
	// and use these to set the varying distance to the vertex in eye space.
	vertexToEyeSpace();
	v_distEye = length(vtxPosEye.xyz);
	
	// Determine the color of the vertex by applying material & lighting, or using a pure color
	if (u_cc3Lighting.isUsingLighting && u_cc3Vertex.hasVertexNormal) {
		// Transform vertex normal using inverse-transpose of modelview and renormalize if needed.
		if (u_cc3Vertex.shouldRescaleNormal) vtxNormEye = normalize(vtxNormEye);	// TODO - rescale without having to normalize
		if (u_cc3Vertex.shouldNormalizeNormal) vtxNormEye = normalize(vtxNormEye);

		v_color = illuminate();
	} else {
		v_color = u_cc3Vertex.hasVertexColor ? a_cc3Color : u_cc3Color;
	}
	
	// Fragment texture coordinates.
	if (u_cc3TextureCount > 0) v_texCoord[0] = a_cc3TexCoord0;
	if (u_cc3TextureCount > 1) v_texCoord[1] = a_cc3TexCoord1;
//	if (u_cc3TextureCount > 0) v_texCoord0 = a_cc3TexCoord0;
//	if (u_cc3TextureCount > 1) v_texCoord1 = a_cc3TexCoord1;
	
	gl_Position = u_cc3Matrices.proj * vtxPosEye;
}

