import sys.io.File;
import haxe.Json;
import sys.FileSystem;
import hxargs.Args;
import net.Network;

typedef Config = {
    datasetDirectory:String,
    testDirectory:String,
    bias:Int,
    dimensions:Int,
    iterations:Int,
    weightSaveInterval:Int,
    showHelp:Bool,
    restoreWeights:Bool,
    silentMisclassifications:Bool
}

private final config:Config = {
    datasetDirectory: null,
    testDirectory: null,
    bias: 0,
    dimensions: 200,
    iterations: 10,
    weightSaveInterval: 2,
    showHelp: false,
    restoreWeights: false,
    silentMisclassifications: false
};

private final version = "1.0.0";

function main() {
    final args = Sys.args();

    final argumentHandler = Args.generate([
        @doc("Shows this dialog")
        ["--help", "-h"] => () -> {
            config.showHelp = true;
        },
        @doc("Directory containing the dataset used for training")
        ["--dataset", "-d"] => path -> {
            config.datasetDirectory = path;
        },
        @doc("Directory containing samples to be tested against the neural network")
        ["--test", "-t"] => path -> {
            config.testDirectory = path;
        },
        @doc("Adjusts the bias")
        ["--bias"] => bias -> {
            config.bias = bias;
        },
        @doc("Dimensions of the sample images used")
        ["--dimensions"] => dimensions -> {
            config.dimensions = dimensions;
        },
        @doc("How many training iterations should be performed")
        ["--iterations", "-i"] => iterations -> {
            config.iterations = iterations;
        },
        @doc("How often the current weights should be saved")
        ["--weightSaveInterval"] => interval -> {
            config.weightSaveInterval = interval;
        },
        @doc("Whether weights should be restored from weights.json")
        ["--restoreWeights"] => () -> {
            config.restoreWeights = true;
        },
        @doc("Hides misclassification message")
        ["--silentMisclassifications"] => () -> {
            config.silentMisclassifications = true;
        },
        _ => input -> {
            config.showHelp = true;
        }
    ]);

    argumentHandler.parse(args);

    if (config.showHelp || args.length == 0) {
        Console.println("Usage: perceptron [-options]");
        Console.println("");
        Console.println("Options:");
        Console.println(argumentHandler.getDoc());
        Sys.exit(0);
    }

    Console.log('<b>Perceptron $version</b>');
    Console.examine(config);
    Console.log();

    final network = new Network(config);
    network.initNetwork();
    if (config.restoreWeights) {
        if (FileSystem.exists("weights.json")) {
            Console.log("Restored weights");
            final weights:Array<Int> = Json.parse(File.getContent("weights.json"));
            network.setWeights(weights);
        } else {
            Console.error("Failed to open weights.json");
            Sys.exit(1);
        }
    }
    if (config.datasetDirectory != null) {
        network.trainDirectory(config.datasetDirectory, config.iterations, config.weightSaveInterval);
    }
    if (config.testDirectory != null) {
        network.testDirectory(config.testDirectory);
    }
}
