##>VERTEX
{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicCamera}}
{{ShaderLibrary.BasicTexture}}

void main(void) {
  vTexCoord = aVertexTexCoord;
  gl_Position = uProjectionMatrix * uCameraMatrix * uModelMatrix * vec4(aVertexPosition, 1.0);
}


##>FRAGMENT

precision mediump float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicTexture}}
  
void main(void) {
  gl_FragColor = texture2D(uSampler, vTexCoord);
}