shader_type canvas_item;
// Dobla de costado los tentáculos del frente (ver TentacleFront). Solo visual.
// El Polygon2D guarda en el canal rojo del color de cada vértice cuánto "punta" es
// (0 = base, que no se mueve; 1 = punta, que se mueve lo máximo).

// Cuánto se mueve la punta de costado. Unidad: px.
uniform float amplitude = 10.0;
// Velocidad de la onda. Unidad: Hz.
uniform float speed = 0.8;

void vertex() {
	float tip = COLOR.r;
	COLOR = vec4(1.0);
	// La posición en x del tentáculo desfasa la onda: cada uno se dobla distinto.
	float phase = MODEL_MATRIX[3].x * 0.037;
	float t = TIME * speed * 6.2831853;
	float wave = sin(t + phase + tip * 2.4) * 0.7 + sin(t * 0.47 + phase * 1.9 + tip * 4.6) * 0.3;
	VERTEX.x += wave * amplitude * tip * tip;
}
