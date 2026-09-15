#pragma once

#include <string>
#include <vector>

// Floor 15, moved into its own translation unit. Same class, same promises.
class Pack {
public:
    Pack(size_t capacity);

    bool add(const std::string& item);      // false if already full
    bool drop(const std::string& item);     // false if it is not in there
    bool has(const std::string& item) const;

    bool full() const;
    size_t size() const;
    size_t capacity() const;
    std::string list() const;               // "potion, rope" or "(empty)"

    // The save file needs them one at a time, which list() cannot give.
    const std::vector<std::string>& items() const;

private:
    std::vector<std::string> items_;
    size_t capacity_;
};
