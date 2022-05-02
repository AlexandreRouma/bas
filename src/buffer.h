#include <algorithm>

template<class T>
class buffer {
public:
    buffer(T& _obj) : obj(_obj) {
        objSize = obj.size();
    }

    int size() {
        return objSize;
    }

    template<typename Func>
    int peek(int count, Func f) {
        int avail = available();
        int peekable = std::min<int>(count, avail);
        for (int i = 0; i < peekable || (count == -1 && i < avail); i++) {
            if (!f(i, obj[cursor + i])) { return i; }
        }
        return (count == -1) ? avail : peekable;
    }

    template<typename Func>
    int consume(int count, Func f) {
        int consumed = peek(count, f);
        cursor += consumed;
        return consumed;
    }

    int consume(int count) {
        int avail = available();
        int peekable = std::min<int>(count, avail);
        int consumed = (count == -1) ? avail : peekable;
        cursor += consumed;
        return consumed;
    }

    int available() {
        return objSize - cursor;
    }

    void seek(int pos) {
        cursor = std::clamp<int>(pos, 0, obj.size());
    }

    int tell() {
        return cursor;
    }

    auto& first() {
        return obj[cursor];
    }

    auto& last() {
        return obj[objSize - 1];
    }

    auto& operator[](int i) {
        return obj[cursor + i];
    }

private:
    T& obj;
    int cursor = 0;
    int objSize = -1;
};