#include <flutter/runtime_effect.glsl>

precision mediump sampler2D;

uniform float top;
uniform float left;
uniform float right;
uniform float bottom;
uniform float windowWidth;
uniform float windowHeight;
uniform sampler2D image;

out vec4 fragColor;

void main(void) {
    vec2 fragCoord = FlutterFragCoord();
    vec2 p = (fragCoord + vec2(left, top)) / vec2(windowWidth, windowHeight);
    fragColor = texture(image, p);
}