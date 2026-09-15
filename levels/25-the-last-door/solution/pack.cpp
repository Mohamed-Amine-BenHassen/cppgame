#include "pack.h"

Pack::Pack(size_t capacity) {
    capacity_ = capacity;
}

bool Pack::add(const std::string& item) {
    if (full()) {
        return false;
    }
    items_.push_back(item);
    return true;
}

bool Pack::drop(const std::string& item) {
    for (size_t i = 0; i < items_.size(); ++i) {
        if (items_[i] == item) {
            items_.erase(items_.begin() + i);
            return true;
        }
    }
    return false;
}

bool Pack::has(const std::string& item) const {
    for (const std::string& it : items_) {
        if (it == item) {
            return true;
        }
    }
    return false;
}

bool Pack::full() const {
    return items_.size() >= capacity_;
}

size_t Pack::size() const {
    return items_.size();
}

size_t Pack::capacity() const {
    return capacity_;
}

std::string Pack::list() const {
    if (items_.empty()) {
        return "(empty)";
    }
    std::string out;
    for (size_t i = 0; i < items_.size(); ++i) {
        if (i > 0) {
            out += ", ";
        }
        out += items_[i];
    }
    return out;
}

const std::vector<std::string>& Pack::items() const {
    return items_;
}
