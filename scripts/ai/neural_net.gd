class_name NeuralNet
extends RefCounted

var sizes: Array[int] = []
var weights: Array = []
var biases: Array = []
var acts: Array = []

func _init(layer_sizes: Array = []) -> void:
	sizes.assign(layer_sizes)
	for l in range(1, sizes.size()):
		var n_in := sizes[l - 1]
		var n_out := sizes[l]
		var w := PackedFloat32Array()
		w.resize(n_in * n_out)
		var limit := sqrt(6.0 / (n_in + n_out))
		for k in w.size():
			w[k] = randf_range(-limit, limit)
		weights.append(w)
		var b := PackedFloat32Array()
		b.resize(n_out)
		biases.append(b)

func forward(x: PackedFloat32Array) -> PackedFloat32Array:
	acts = [x]
	var a := x
	for l in weights.size():
		var n_in := sizes[l]
		var n_out := sizes[l + 1]
		var w: PackedFloat32Array = weights[l]
		var b: PackedFloat32Array = biases[l]
		var out := PackedFloat32Array()
		out.resize(n_out)
		for j in n_out:
			var s := b[j]
			var row := j * n_in
			for i in n_in:
				s += w[row + i] * a[i]
			out[j] = tanh(s)
		acts.append(out)
		a = out
	return a

func train(x: PackedFloat32Array, target: PackedFloat32Array, rate: float) -> float:
	var out := forward(x)
	var delta := PackedFloat32Array()
	delta.resize(out.size())
	var error := 0.0
	for j in out.size():
		var e := out[j] - target[j]
		error += e * e
		delta[j] = e * (1.0 - out[j] * out[j])
	for l in range(weights.size() - 1, -1, -1):
		var n_in := sizes[l]
		var n_out := sizes[l + 1]
		var a_in: PackedFloat32Array = acts[l]
		var w: PackedFloat32Array = weights[l]
		var b: PackedFloat32Array = biases[l]
		var back := PackedFloat32Array()
		back.resize(n_in)
		for j in n_out:
			var d := delta[j]
			var row := j * n_in
			for i in n_in:
				back[i] += w[row + i] * d 
				w[row + i] -= rate * d * a_in[i]
			b[j] -= rate * d
		weights[l] = w 
		biases[l] = b
		if l > 0:
			for i in n_in:
				back[i] *= 1.0 - a_in[i] * a_in[i]
			delta = back
	return error

func copy() -> NeuralNet:
	var c := NeuralNet.new()
	c.sizes = sizes.duplicate()
	for w in weights:
		c.weights.append(PackedFloat32Array(w))
	for b in biases:
		c.biases.append(PackedFloat32Array(b))
	return c

func mutate(rate: float, size: float) -> void:
	for l in weights.size():
		var w: PackedFloat32Array = weights[l]
		for k in w.size():
			if randf() < rate:
				w[k] += randfn(0.0, size)
		weights[l] = w
		var b: PackedFloat32Array = biases[l]
		for k in b.size():
			if randf() < rate:
				b[k] += randfn(0.0, size)
		biases[l] = b

func save(path: String) -> void:
	var data := {"sizes": sizes, "weights": weights.map(func(w): return Array(w)), "biases": biases.map(func(b): return Array(b))}
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()

static func load_file(path: String) -> NeuralNet:
	if not FileAccess.file_exists(path):
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var net := NeuralNet.new()
	net.sizes.assign(data["sizes"].map(func(v): return int(v)))
	for w in data["weights"]:
		net.weights.append(PackedFloat32Array(w))
	for b in data["biases"]:
		net.biases.append(PackedFloat32Array(b))
	return net
