//
//  Path.cpp
//  PathKit
//
//  Created by Michael Eisel on 3/10/20.
//

#include "include/CDeps.h"
#include <cstring>
#include <vector>
#include <string>

using namespace std;

void PATFreePathComponents(const char **components, void *temp) {
    delete components;
    vector<string> *array = (vector<string> *)temp;
    delete array;
}

const char **PATPathComponents(const char *path, size_t *count, void **temp) {
    if (!*path) {
        *count = 0;
        return NULL;
    }
    vector<string> *strings = new vector<string>();
    size_t curPos = 0;
    size_t endPos = strlen(path);
    if (path[curPos] == '/') {
        strings->push_back("/");
    }
    while (curPos < endPos) {
        while (curPos < endPos && path[curPos] == '/') {
            curPos++;
        }
        if (curPos == endPos) {
            break;
        }
        auto curEnd = curPos;
        while (curEnd < endPos && path[curEnd] != '/') {
            curEnd++;
        }
        string str(path + curPos, curEnd - curPos);
        strings->push_back(str);
        curPos = curEnd;
    }
    if (endPos > 1 && path[endPos - 1] == '/') {
        strings->push_back("/");
    }
    const char **components = new const char *[strings->size()];
    for (int i = 0; i < strings->size(); i++) {
        components[i] = (*strings)[i].c_str();
    }
    *count = strings->size();
    return components;
}
