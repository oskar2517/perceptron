package net;

import haxe.io.BytesInput;
import haxe.io.Bytes;

function parseBitmap(data:Bytes):Array<Int> {
    final pixels:Array<Int> = [];
    final input = new BytesInput(data);
    final header = input.read(54);

    final width = header.getInt32(18);
    final height = header.getInt32(22);

    final rowPadded = (width * 3 + 3) & (~3);

    for (_ in 0...height) {
        final pixelBytes = input.read(rowPadded);

        var j = 0;
        while (j < width * 3) {
            final b = pixelBytes.get(j);
            final g = pixelBytes.get(j + 1);
            final r = pixelBytes.get(j + 2);

            if (r == 0 && g == 0 && b == 0) {
                pixels.push(1);
            } else if (r == 255 && g == 255 && b == 255) {
                pixels.push(0);
            } else {
                Console.error("Bitmap contains illegal colors. Only black and white are supported.");
                Sys.exit(1);
            }

            j += 3;
        }
    }

    return pixels;
}