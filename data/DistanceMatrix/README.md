# **Distance Matrix**
> This directory contains compressed precompiled distance matrix
---

## **Download:**
In order to use the compressed file, [download](https://firebasestorage.googleapis.com/v0/b/pbp-loggi-2021.appspot.com/o/CompressedDistanceMatrix.zip?alt=media) the file and place it in this directory.

Unzip the file using the command:
```bash
unzip CompressedDistanceMatrix.zip
```
---
> PS: Make sure to keep all `*.gz` files

## **Format:**
```json
{
    // Distance matrix JSON compressed file example
    // Each value must be of type <FLOAT> or <INT>
    "Distance_Table": [
        [0.0, 1.0, 1.0, 3.0, 2.0, 4.0],
        [1.0, 0.0, 1.0, 3.0, 2.0, 4.0],
        [1.0, 1.0, 0.0, 3.0, 2.0, 4.0],
        [1.0, 1.0, 3.0, 0.0, 2.0, 4.0],
        [1.0, 1.0, 3.0, 2.0, 0.0, 4.0],
        [1.0, 1.0, 3.0, 2.0, 4.0, 0.0]
    ]
}
```