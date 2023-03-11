# About

Digital lava lamp designed for the Xilinx Artix-7 35T and based on a fixed-point arithmetic implementation of the metaballs algorithm.

For a finite sample space (in this case, 2048 pixels), the contribution of each metaball is summed to determine the sample value, where the contribution is given roughly by the inverse square law function of the metaball's position. Above a specific threshold, the sample is considered lit; below it, the sample is unlit. To determine the value of each pixel, a per-pixel colour map is precomputed from a linear gradient and stored in ROM upon design synthesis. Thus, when a given sample is determined to be lit, the gradient sample for the corresponding pixel is read from ROM and subsequently written to a double buffer. The double buffer consists of two BRAM-based buffers that can be swapped between reading and writing entities. Pixel data values are simultaneously read from the double buffer by a display controller, which drives the frame to an external LED matrix. The controller uses a binary coded modulation (BCM) scheme to achieve a 12-bit colour depth with 4 bits per channel.

For a further explanation of the metaball math (with visuals), please refer to the following article: https://jamie-wong.com/2014/08/19/metaballs-and-marching-squares/

# Demo

https://user-images.githubusercontent.com/36207488/224456284-f23c4d17-3151-4060-87bd-e4996f75e2a3.mp4
