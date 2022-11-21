I couldn't find anybody documenting what happens to the -Y axis world generation when a
Minecraft world is updated from 1.17<=, where the -Y limit is 0, to post-1.18 where it's
-64; so I thought I should do it myself.

To my surprise, in a world I created in 1.17 then immediately copied to 1.19, the bedrock
at layer 0 was replaced with 1.18 world generation down to -64 — as if the world were generated
in 1.18.

![](/img/1.18_bedrock_ow.png)

Though in immediate hindsight, this probably is the best solution. There aren't any blocks that
can be placed on bedrock but not deepslate, and blocks can't appear in the void, so there's
nothing to be inadvertently overwritten.

Out of further curiousity, I used [Yarn](https://github.com/FabricMC/yarn) to
peek into the code that does this; turns out it's kept in `client/net/minecraft/world/chunk/BelowZeroRetrogen.java`:

<pre><code class="language-java">
public static void replaceOldBedrock(ProtoChunk chunk) {
    BlockPos.iterate(0, 0, 0, 15, 4, 15).forEach(pos -> {
        if (chunk.getBlockState(pos).isOf(Blocks.BEDROCK)) {
            chunk.setBlockState(pos, Blocks.DEEPSLATE.getDefaultState(), false);
        }
    });
}
</code></pre>

However it appears as if Minecraft checks if bedrock is missing where the worldgen would expect
it to be, and if it is, it's _left_ missing instead of being replaced by bedrock.

<pre><code class="language-java">
public void fillColumnsWithAirIfMissingBedrock(ProtoChunk chunk) {
    HeightLimitView lv = chunk.getHeightLimitView();
    int i = lv.getBottomY();
    int j = lv.getTopY() - 1;

    for (int k = 0; k < 16; ++k) {
        for (int l = 0; l < 16; ++l) {
            if (!this.isColumnMissingBedrock(k, l)) continue;
            BlockPos.iterate(k, i, l, k, j, l).forEach(pos ->
                chunk.setBlockState(pos, Blocks.AIR.getDefaultState(), false));
        }
    }
}
</code></pre>

And that is exactly so! Here's a hole made in bedrock at level 0 in 1.17:

![](/img/1.17_hole.png)

And that same world opened in 1.19:

![](/img/1.18_level_zero_hole.png)

![](/img/1.18_hole_look_down.png)

![](/img/1.18_kept_hole.png)

This was probably added so as to not greatly annoy technical Minecrafters :-)

And as an aside — whether a world has undergone below-zero retrogeneration apparently sticks around,
serialized into the world save.

Neat.