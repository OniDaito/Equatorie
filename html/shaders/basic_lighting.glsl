##>VERTEX
{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicCamera}}
{{ShaderLibrary.BasicVertexNormals}}
{{ShaderLibrary.BasicTexture}}


uniform vec3 uPointLightPos[10];
varying vec4 vPointLightPos[10];
varying vec4 vTransformedNormal;
varying vec4 vPosition;
varying vec4 vEyePosition;
uniform int uNumLights;

void main(void) {
  vPosition =   uModelMatrix * vec4(aVertexPosition, 1.0);
  gl_Position =  uProjectionMatrix * uCameraMatrix * vPosition;

  vTexCoord = aVertexTexCoord;

  for (int i=0; i < 10; i++){
     if (i >= uNumLights)
      break;
    vPointLightPos[i] =  vec4(uPointLightPos[i], 1.0);
  }

  vEyePosition = uCameraInverseMatrix * vPosition;

  vTransformedNormal = vec4(uNormalMatrix * aVertexNormal,1.0);
}

##>FRAGMENT
precision mediump float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicVertexNormals}}
{{ShaderLibrary.BasicTexture}}

varying vec4 vTransformedNormal;
varying vec4 vPosition;
varying vec4 vEyePosition;

uniform vec3 uAmbientLightingColor;

uniform vec3 uMaterialAmbientColor;
uniform vec3 uMaterialDiffuseColor;
uniform vec3 uMaterialSpecularColor;
uniform float uMaterialShininess;
uniform vec3 uMaterialEmissiveColor;

varying vec4 vPointLightPos[10];
uniform vec3 uPointLightDiffuse[10];
uniform vec3 uPointLightSpecular[10];
uniform vec3 uPointLightAttenuation[10];
uniform int uNumLights;

void main(void) {
  vec3 ambientLightWeighting = uAmbientLightingColor;
  float alpha = 1.0;

  vec3 normal = normalize(vTransformedNormal.xyz);
  vec3 specularLightWeighting = vec3(0.0, 0.0, 0.0);
  vec3 diffuseLightWeighting = vec3(0.0, 0.0, 0.0);
  vec3 eyeDirection = normalize(vEyePosition.xyz);
 
  for (int i =0; i < 10; i++) {
    if (i >= uNumLights)
      break;
    vec3 lightDirection = normalize(vPointLightPos[i].xyz - vPosition.xyz);
    vec3 reflectionDirection = reflect(-lightDirection, normal);

    float specularLightBrightness = pow(max(dot(reflectionDirection, eyeDirection), 0.0), uMaterialShininess);
    specularLightWeighting = specularLightWeighting + (uPointLightSpecular[i] * specularLightBrightness);

    float diffuseLightBrightness = max(dot(normal, lightDirection), 0.0);
    diffuseLightWeighting = diffuseLightWeighting + (uPointLightDiffuse[i] * diffuseLightBrightness);
  }

  vec3 materialSpecularColor = uMaterialSpecularColor;
 
  vec4 textureColor = texture2D(uSampler, vTexCoord);
  vec3 materialAmbientColor = uMaterialAmbientColor * textureColor.rgb;
  vec3 materialDiffuseColor = uMaterialDiffuseColor * textureColor.rgb;
  vec3 materialEmissiveColor = uMaterialEmissiveColor * textureColor.rgb;
 
  alpha = textureColor.a;

  gl_FragColor = vec4(
    materialAmbientColor * ambientLightWeighting
    + materialDiffuseColor * diffuseLightWeighting
    + materialSpecularColor * specularLightWeighting
    + materialEmissiveColor,
    alpha
  );

  //gl_FragColor = vec4(normal.x + 1.0 / 2.0,  normal.y + 1.0 / 2.0, normal.z + 1.0 / 2.0, 1.0);
} 

   