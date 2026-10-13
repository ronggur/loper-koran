// Shader warna bayangan (ART_DIRECTION 2.1 no. 5 dan 2.3; usulan run fase1b-umpan-balik, dicek di probe render cek_render).
// Piksel penanda bayangan tanah yang dipanggang di sprite (#000000 alpha 71/255) diganti warna bayangan aktif dengan alpha yang
// sama; piksel lain tidak berubah. Warna bayangan diisi dari kode (Palette, nanti per distrik dan waktu, ART_DIRECTION 2.5),
// tanpa hint source_color supaya nilainya dipakai apa adanya di ruang warna 2D renderer Compatibility. Modulate node tetap berlaku.
shader_type canvas_item;

uniform vec4 warna_bayangan = vec4(0.0, 0.0, 0.0, 1.0);
// Alpha piksel penanda: 71/255.
uniform float alpha_penanda = 0.278431;
// Toleransi pembanding (sekitar setengah langkah 8 bit).
uniform float toleransi = 0.002;

varying vec4 warna_titik;

void vertex() {
	warna_titik = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	bool penanda = max(max(texel.r, texel.g), texel.b) < toleransi && abs(texel.a - alpha_penanda) < toleransi;
	if (penanda) {
		COLOR = vec4(warna_bayangan.rgb, texel.a) * warna_titik;
	}
}
