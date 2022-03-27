package net;

private typedef NeuronConnection = {
	neuron:Neuron,
	weight:Int
}

class Neuron {
    
	public var active(default, set):Int;

	public var ancestors(default, null):Array<NeuronConnection> = [];
	private final bias:Int;

	public function new(bias:Int) {
        this.bias = bias;
    }

	private function set_active(value:Int):Int {
		return this.active = value;
	}

	public function addAncestor(neuron:Neuron):Void {
		ancestors.push({
			neuron: neuron,
			weight: 0
		});
	}

	public function update():Void {
 		final sum = Lambda.fold(ancestors, (connection, result) -> {
			return result + connection.neuron.active * connection.weight;
		}, 0);

		active = sum > bias ? 1 : 0;
	}

    public function addWeights():Void {
        ancestors.map(connection -> {
            connection.weight += connection.neuron.active;
        });
    }

    public function subtractWeights():Void {
        ancestors.map(connection -> {
            connection.weight -= connection.neuron.active;
        });
    }
}
