#pragma once
#include <stdlib.h>
#include <stdint.h>
#include <vector>
#include <map>
#include <stdexcept>
#include <string.h>

template<class T>
class BinaryBuilder {
public:
    BinaryBuilder(int cap = 64000, int cursor = 0) {
        expand(cap);
        seek(cursor);
    }

    ~BinaryBuilder() {
        free(_data);
    }

    size_t tell() { return cursor; }

    void seek(size_t addr) {
        cursor = addr;
    }

    void write(T* data, size_t len) {
        while (cursor + len > capacity) { doubleCapacity(); }
        memcpy(&_data[cursor], data, len * sizeof(T));
        size = std::max<size_t>(size, cursor + len);
        cursor += len;
    }

    void put(T data) {
        write(&data, 1);
    }

    void writeAt(T* data, size_t len, size_t pos) {
        size_t opos = tell();
        seek(pos);
        write(data, len);
        seek(opos);
    }

    void putAt(T data, size_t pos) {
        writeAt(&data, 1, pos);
    }

    const T* getData() { return _data; }

    int getSize() {
        return size;
    }

private:
    void doubleCapacity() {
        expand(capacity * 2);
    }

    void expand(size_t newCapacity) {
        if (capacity >= newCapacity) { return; }
        if (_data) {
            _data = (T*)realloc(_data, newCapacity * sizeof(T));
        }
        else {
            _data = (T*)malloc(newCapacity * sizeof(T));
        }
        capacity = newCapacity;
    }

    size_t cursor = 0;
    size_t size = 0;
    size_t capacity = 0;
    T* _data = NULL;
};
