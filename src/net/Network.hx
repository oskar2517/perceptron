package net;

import Main.Config;
import haxe.Json;
import net.Bitmap.parseBitmap;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

private typedef Sample = {
    data:Array<Int>,
    expected:Int
}

class Network {

    private final dimensions:Int;
    private final inputNeurons:Array<Neuron> = [];
    private final outputNeuron:Neuron;
    private final bias:Int;
    private final silentMisclassifications:Bool;

    public function new(config:Config) {
        this.dimensions = config.dimensions;
        this.bias = config.bias;
        this.silentMisclassifications = config.silentMisclassifications;

        outputNeuron = new Neuron(bias);
    }

    public function initNetwork():Void {
        for (_ in 0...dimensions * dimensions) {
            final neuron = new Neuron(bias);
            inputNeurons.push(neuron);
            outputNeuron.addAncestor(neuron);
        }
    }

    public function getWeights():Array<Int> {
        return outputNeuron.ancestors.map(connection -> connection.weight);
    }

    public function setWeights(weights:Array<Int>):Void {
        if (weights.length != outputNeuron.ancestors.length) {
            Console.error('Unexpected weight dimensions. Neurons: ${outputNeuron.ancestors.length}, Provided: ${weights.length}');
            Sys.exit(1);
        }
        for (i => weight in weights) {
            outputNeuron.ancestors[i].weight = weight;
        }
    }

    public function test(data:Array<Int>):Int {
        if (data.length != inputNeurons.length) {
            Console.error('Unexpected data dimensions. Neurons: ${inputNeurons.length}, Data: ${data.length}.');
            Sys.exit(1);
        }

        outputNeuron.active = 0;
        for (i => d in data) {
            inputNeurons[i].active = d;
        }

        outputNeuron.update();

        return outputNeuron.active;
    }

    public function train(data:Array<Int>, expected:Int):Void {
        test(data);

        if (expected == 1 && outputNeuron.active == 0) {
            outputNeuron.addWeights();
        } else if (expected == 0 && outputNeuron.active == 1) {
            outputNeuron.subtractWeights();
        }
    }

    private function shuffleArray(array:Array<Sample>):Array<Sample> {
        var counter = array.length;
    
        while (counter > 0) {
            final index = Math.floor(Math.random() * counter);
            counter--;
    
            final temp = array[counter];
            array[counter] = array[index];
            array[index] = temp;
        }
    
        return array;
    }

    public function trainDirectory(path:String, iterations:Int, weightSaveInterval:Int):Void {
        final samples:Array<Sample> = [];

        final dataset = FileSystem.readDirectory(path);
        Console.log('Loading ${dataset.length} samples from dataset...');
        for (fileName in dataset) {
            final fileNamePrefix = fileName.substr(0, 2);
            final expected = if (fileNamePrefix == "0_") {
                0;
            } else if (fileNamePrefix == "1_") {
                1;
            } else {
                Console.error("Wrong sample naming scheme. File names must start with '1_' or '0_'.");
                Sys.exit(1);
                0;
            }
    
            samples.push({
                data: parseBitmap(File.getBytes(Path.join([path, fileName]))),
                expected: expected
            });
        }
        Console.log('Sucessfully read ${samples.length} samples from dataset');
        Console.log('Beginning training for $iterations iterations with bias $bias...');
        for (i in 0...iterations) {
            if (weightSaveInterval != 0 && i % weightSaveInterval == 0 && i != 0) {
                saveWeights();
            }

            Console.print("#");
            for (s in shuffleArray(samples)) {
                train(s.data, s.expected);
            }
        }
        if (weightSaveInterval != 0) {
            saveWeights();
        }
        Console.println();
        Console.log("Training complete");
    }

    private function saveWeights():Void {
        final currentWeights = getWeights();
        final encodedWeights = Json.stringify(currentWeights);
        File.saveContent("weights.json", encodedWeights); 
    }

    public function testDirectory(path:String) {
        Console.log("Testing neural network against samples in test directory...");
        var correct = 0;

        final samples = FileSystem.readDirectory(path);
        for (fileName in samples) {
            final fileNamePrefix = Std.parseInt(fileName.substr(0, 1));
            final sample = parseBitmap(File.getBytes(Path.join([path, fileName])));
            final result = test(sample);
            if (fileNamePrefix == result) {
                correct += 1;
            } else if (!silentMisclassifications) {
                Console.warn('${fileName} was missclassified');
            }
        }
    
        Console.log('<b>$correct/${samples.length} (${(correct/samples.length) * 100}%)</b> samples classified successfully');
    }
}