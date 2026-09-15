#include <iostream>
#include <string>
#include <vector>

class Pack {
public:
    Pack(size_t capacity) {
        capacity_ = capacity;
    }

    bool add(const std::string& item) {
        if (full()) {
            return false;              // refuse cleanly, change nothing
        }
        items_.push_back(item);
        return true;
    }

    bool drop(const std::string& item) {
        for (size_t i = 0; i < items_.size(); ++i) {
            if (items_[i] == item) {
                items_.erase(items_.begin() + i);
                return true;
            }
        }
        return false;
    }

    bool has(const std::string& item) const {
        for (const std::string& it : items_) {
            if (it == item) {
                return true;
            }
        }
        return false;
    }

    bool full() const {
        return items_.size() >= capacity_;
    }

    size_t size() const {
        return items_.size();
    }

    size_t capacity() const {
        return capacity_;
    }

    std::string list() const {
        if (items_.empty()) {
            return "(empty)";
        }
        std::string out;
        for (size_t i = 0; i < items_.size(); ++i) {
            if (i > 0) {
                out += ", ";           // between, never trailing
            }
            out += items_[i];
        }
        return out;
    }

private:
    std::vector<std::string> items_;
    size_t capacity_;
};

// const Pack& - so every method called below has to be const too
void report(const Pack& p) {
    std::cout << "-- pack (" << p.size() << "/" << p.capacity() << ") --\n";
    std::cout << p.list() << "\n";
}

int main() {
    Pack pack(3);

    report(pack);

    std::cout << "add torch -> "   << (pack.add("torch")   ? "yes" : "no") << "\n";
    std::cout << "add rope -> "    << (pack.add("rope")    ? "yes" : "no") << "\n";
    std::cout << "add rations -> " << (pack.add("rations") ? "yes" : "no") << "\n";
    std::cout << "add lantern -> " << (pack.add("lantern") ? "yes" : "no") << "\n";

    report(pack);

    std::cout << "has rope: "   << (pack.has("rope")  ? "yes" : "no") << "\n";
    std::cout << "drop rope -> " << (pack.drop("rope") ? "yes" : "no") << "\n";
    std::cout << "drop rope -> " << (pack.drop("rope") ? "yes" : "no") << "\n";
    std::cout << "has rope: "   << (pack.has("rope")  ? "yes" : "no") << "\n";

    report(pack);

    return 0;
}
