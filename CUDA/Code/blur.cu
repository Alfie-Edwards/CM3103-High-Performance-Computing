#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include <cuda.h>


static int const height = 521,
                 width  = 428,
                 maxLineLength = 200,
                 maxHeaderSize = 5,
                 maxX = width - 1,
                 maxY = height - 1,
                 arraySize = width * height * sizeof(int);


void readInputFile (int h_R[width][height], int h_G[width][height], int h_B[width][height], char header[maxHeaderSize][maxLineLength], int *headerSize)
{
    unsigned int h1, h2, h3;
    int x = 0, y = 0;
    char *sptr, line[maxLineLength];
    FILE *fp;
    fp = fopen("David.ps", "r");

    *headerSize = 0;
 
    while(! feof(fp))
    {
        fscanf(fp, "\n%[^\n]", line);
        if (*headerSize < 5) {
            strcpy((char *)header[(*headerSize)++], (char *)line);
        }
        else {
            for (sptr = &line[0]; *sptr != '\0'; sptr += 6) {
                sscanf(sptr,"%2x",&h1);
                sscanf(sptr+2,"%2x",&h2);
                sscanf(sptr+4,"%2x",&h3);
                
                if (x == width) {
                    x = 0;
                    y++;
                }
                if (y < height) {
                    h_R[x][y] = h1;
                    h_G[x][y] = h2;
                    h_B[x][y] = h3;
                }
                x++;
            }
        }
    }
    fclose(fp);
}


void writeOutputFile (int h_R[width][height], int h_G[width][height], int h_B[width][height], char header[maxHeaderSize][maxLineLength], int headerSize)
{
    int linelen = 12,
        charPos = 0;
    FILE *fout;

    fout= fopen("DavidBlur.ps", "w");
    for (int i = 0; i < headerSize; i++) fprintf(fout,"\n%s", header[i]);
    fprintf(fout,"\n");

    for(int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            fprintf(fout, "%02x%02x%02x", h_R[x][y], h_G[x][y], h_B[x][y]);
            if (++charPos == linelen) {
                fprintf(fout,"\n");
                charPos = 0;
            }
        }
    }
    fclose(fout);
}


void allocateDeviceMemory (int (**d_RIn)[width][height], int (**d_GIn)[width][height], int (**d_BIn)[width][height], int (**d_ROut)[width][height], int (**d_GOut)[width][height], int (**d_BOut)[width][height])
{
    cudaMalloc(d_RIn, arraySize);
    cudaMalloc(d_GIn, arraySize);
    cudaMalloc(d_BIn, arraySize);
    cudaMalloc(d_ROut, arraySize);
    cudaMalloc(d_GOut, arraySize);
    cudaMalloc(d_BOut, arraySize);
}


void freeDeviceMemory (int d_RIn[width][height], int d_GIn[width][height], int d_BIn[width][height], int d_ROut[width][height], int d_GOut[width][height], int d_BOut[width][height])
{
    cudaFree(d_RIn);
    cudaFree(d_GIn);
    cudaFree(d_BIn);
    cudaFree(d_ROut);
    cudaFree(d_GOut);
    cudaFree(d_BOut);
}


void copyMemoryToDevice (int h_R[width][height], int h_G[width][height], int h_B[width][height], int d_RIn[width][height], int d_GIn[width][height], int d_BIn[width][height])
{
    cudaMemcpy(d_RIn, h_R, arraySize, cudaMemcpyHostToDevice);
    cudaMemcpy(d_GIn, h_G, arraySize, cudaMemcpyHostToDevice);
    cudaMemcpy(d_BIn, h_B, arraySize, cudaMemcpyHostToDevice);
}


void copyMemoryFromDevice (int d_ROut[width][height], int d_GOut[width][height], int d_BOut[width][height], int h_R[width][height], int h_G[width][height], int h_B[width][height])
{
    cudaMemcpy(h_R, d_ROut, arraySize, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_G, d_GOut, arraySize, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_B, d_BOut, arraySize, cudaMemcpyDeviceToHost);
}


__global__
void blurKernel (int d_RIn[width][height], int d_GIn[width][height], int d_BIn[width][height], int d_ROut[width][height], int d_GOut[width][height], int d_BOut[width][height])
{
    int x = blockIdx.x * blockDim.x + threadIdx.x,
        y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x != 0 && x != maxX && y != 0 && y != maxY) {
        d_ROut[x][y] = (d_RIn[x+1][y] + d_RIn[x-1][y] + d_RIn[x][y+1] + d_RIn[x][y-1]) / 4;
        d_GOut[x][y] = (d_GIn[x+1][y] + d_GIn[x-1][y] + d_GIn[x][y+1] + d_GIn[x][y-1]) / 4;
        d_BOut[x][y] = (d_BIn[x+1][y] + d_BIn[x-1][y] + d_BIn[x][y+1] + d_BIn[x][y-1]) / 4;
    }
    else if (x == maxX && y != 0 && y != maxY) {
        d_ROut[x][y] = (                d_RIn[x-1][y] + d_RIn[x][y+1] + d_RIn[x][y-1]) / 3;
        d_GOut[x][y] = (                d_GIn[x-1][y] + d_GIn[x][y+1] + d_GIn[x][y-1]) / 3;
        d_BOut[x][y] = (                d_BIn[x-1][y] + d_BIn[x][y+1] + d_BIn[x][y-1]) / 3;
    }
    else if (x == 0 && y != 0 && y != maxY) {
        d_ROut[x][y] = (d_RIn[x+1][y]                 + d_RIn[x][y+1] + d_RIn[x][y-1]) / 3;
        d_GOut[x][y] = (d_GIn[x+1][y]                 + d_GIn[x][y+1] + d_GIn[x][y-1]) / 3;
        d_BOut[x][y] = (d_BIn[x+1][y]                 + d_BIn[x][y+1] + d_BIn[x][y-1]) / 3;
    }
    else if (y == maxY && x != 0 && x != maxX) {
        d_ROut[x][y] = (d_RIn[x+1][y] + d_RIn[x-1][y]                 + d_RIn[x][y-1]) / 3;
        d_GOut[x][y] = (d_GIn[x+1][y] + d_GIn[x-1][y]                 + d_GIn[x][y-1]) / 3;
        d_BOut[x][y] = (d_BIn[x+1][y] + d_BIn[x-1][y]                 + d_BIn[x][y-1]) / 3;
    }
    else if (y == 0 && x != 0 && x != maxX) {
        d_ROut[x][y] = (d_RIn[x+1][y] + d_RIn[x-1][y] + d_RIn[x][y+1]                ) / 3;
        d_GOut[x][y] = (d_GIn[x+1][y] + d_GIn[x-1][y] + d_GIn[x][y+1]                ) / 3;
        d_BOut[x][y] = (d_BIn[x+1][y] + d_BIn[x-1][y] + d_BIn[x][y+1]                ) / 3;
    }
    else if (x == maxX && y == 0) {
        d_ROut[x][y] = (                d_RIn[x-1][y] + d_RIn[x][y+1]                ) / 2;
        d_GOut[x][y] = (                d_GIn[x-1][y] + d_GIn[x][y+1]                ) / 2;
        d_BOut[x][y] = (                d_BIn[x-1][y] + d_BIn[x][y+1]                ) / 2;
    }
    else if (x == 0 && y == maxY) {
        d_ROut[x][y] = (d_RIn[x+1][y]                                 + d_RIn[x][y-1]) / 2;
        d_GOut[x][y] = (d_GIn[x+1][y]                                 + d_GIn[x][y-1]) / 2;
        d_BOut[x][y] = (d_BIn[x+1][y]                                 + d_BIn[x][y-1]) / 2;
    }
    else if (x == maxX && y == maxY) {
        d_ROut[x][y] = (                d_RIn[x-1][y]                 + d_RIn[x][y-1]) / 2;
        d_GOut[x][y] = (                d_GIn[x-1][y]                 + d_GIn[x][y-1]) / 2;
        d_BOut[x][y] = (                d_BIn[x-1][y]                 + d_BIn[x][y-1]) / 2;
    }
    else if (x == 0 && y == 0) {
        d_ROut[x][y] = (d_RIn[x+1][y]                 + d_RIn[x][y+1]                ) / 2;
        d_GOut[x][y] = (d_GIn[x+1][y]                 + d_GIn[x][y+1]                ) / 2;
        d_BOut[x][y] = (d_BIn[x+1][y]                 + d_BIn[x][y+1]                ) / 2;
    }
}


void outputTimingResults (struct timeval t1, struct timeval t2, struct timeval t3, struct timeval t4, struct timeval t5, struct timeval t6, struct timeval t7, struct timeval t8)
{
    // Convert times to seconds
    double t1_s = t1.tv_sec + t1.tv_usec / 1000000.0,
           t2_s = t2.tv_sec + t2.tv_usec / 1000000.0,
           t3_s = t3.tv_sec + t3.tv_usec / 1000000.0,
           t4_s = t4.tv_sec + t4.tv_usec / 1000000.0,
           t5_s = t5.tv_sec + t5.tv_usec / 1000000.0,
           t6_s = t6.tv_sec + t6.tv_usec / 1000000.0,
           t7_s = t7.tv_sec + t7.tv_usec / 1000000.0,
           t8_s = t8.tv_sec + t8.tv_usec / 1000000.0;

    // Calculate intervals between times
    double t1t2_s = t2_s - t1_s,
           t2t3_s = t3_s - t2_s,
           t3t4_s = t4_s - t3_s,
           t4t5_s = t5_s - t4_s,
           t5t6_s = t6_s - t5_s,
           t6t7_s = t7_s - t6_s,
           t7t8_s = t8_s - t7_s;

    // Print final timings
    printf("Read Input File: %f\n", t1t2_s);
    printf("Allocate Device Memory: %f\n", t2t3_s);
    printf("Copy Memory to Device: %f\n", t3t4_s);
    printf("Blur: %f\n", t4t5_s);
    printf("Copy Memory from Device: %f\n", t5t6_s);
    printf("Free Memory on Device: %f\n", t6t7_s);
    printf("Write Output File: %f\n", t7t8_s);
}


int main (int argc, const char * argv[])
{
    // Record the time at different points in execution
    struct timeval t1, t2, t3, t4, t5, t6, t7, t8;
    char header[maxHeaderSize][maxLineLength];
    int nblurs = atoi(argv[1]),
        gridWidth,
        gridHeight,
        headerSize,
        blockWidth,
        blockHeight,
        h_R[width][height],
        h_G[width][height],
        h_B[width][height],
        // Use pointers to allow swapping input and output arrays in-between blurs without moving memory around 
        (*swap)[width][height],
        (*d_RIn)[width][height],
        (*d_GIn)[width][height],
        (*d_BIn)[width][height],
        (*d_ROut)[width][height],
        (*d_GOut)[width][height],
        (*d_BOut)[width][height];
    
    gettimeofday(&t1, NULL);
    readInputFile(h_R, h_G, h_B, header, &headerSize);
    gettimeofday(&t2, NULL);
    allocateDeviceMemory(&d_RIn, &d_GIn, &d_BIn, &d_ROut, &d_GOut, &d_BOut);
    gettimeofday(&t3, NULL);
    copyMemoryToDevice(h_R, h_G, h_B, *d_RIn, *d_GIn, *d_BIn);
    gettimeofday(&t4, NULL);
    
    blockWidth  = 16;
    blockHeight = 16;
    gridWidth  = ceil((double)width  / blockWidth);
    gridHeight = ceil((double)height / blockHeight);
    dim3 dimGrid(gridWidth,   gridHeight,  1);
    dim3 dimBlock(blockWidth, blockHeight, 1);
    
    // nblurs passed as commandline argument to avoid interfering with timing
    // nblurs = 10;
    // printf("\nGive the number of times to blur the image\n");
    // int icheck = scanf("%d", &nblurs);

    // Do first blur without swapping output and input pointers
    blurKernel<<<dimGrid, dimBlock>>>(*d_RIn, *d_GIn, *d_BIn, *d_ROut, *d_GOut, *d_BOut);
    for (int i = 1; i < nblurs; i++) {
        // Swap input and output between blurs
        swap   = d_RIn;
        d_RIn  = d_ROut;
        d_ROut = swap;
        swap   = d_GIn;
        d_GIn  = d_GOut;
        d_GOut = swap;
        swap   = d_BIn;
        d_BIn  = d_BOut;
        d_BOut = swap;

        blurKernel<<<dimGrid, dimBlock>>>(*d_RIn, *d_GIn, *d_BIn, *d_ROut, *d_GOut, *d_BOut);
    }
    gettimeofday(&t5, NULL);
    copyMemoryFromDevice(*d_ROut, *d_GOut, *d_BOut, h_R, h_G, h_B);
    gettimeofday(&t6, NULL);
    freeDeviceMemory(*d_RIn, *d_GIn, *d_BIn, *d_ROut, *d_GOut, *d_BOut);
    gettimeofday(&t7, NULL);
    writeOutputFile(h_R, h_G, h_B, header, headerSize);
    gettimeofday(&t8, NULL);
    
    outputTimingResults(t1, t2, t3, t4, t5, t6, t7, t8);
}
