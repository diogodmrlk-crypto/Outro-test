#include "execution.hpp"

#include <cstdlib>
#include <mutex>
#include <string>

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "luacode.h"
}

namespace {
std::mutex g_executionMutex;

void appendError(lua_State* L, std::string& output) {
    const char* message = lua_tostring(L, -1);
    output = message ? message : "Luau returned an unknown error";
}
}

int ExecuteScript(const std::string& source, std::string& output) {
    std::lock_guard<std::mutex> lock(g_executionMutex);
    output.clear();

    if (source.empty()) {
        output = "O script está vazio.";
        return -1;
    }

    lua_State* L = luaL_newstate();
    if (!L) {
        output = "Não foi possível criar a VM Luau.";
        return -2;
    }

    luaL_openlibs(L);
    luaL_sandbox(L);

    size_t bytecodeSize = 0;
    char* bytecode = luau_compile(
        source.data(),
        source.size(),
        nullptr,
        &bytecodeSize
    );

    if (!bytecode || bytecodeSize == 0) {
        if (bytecode) free(bytecode);
        output = "Falha ao compilar o código Luau.";
        lua_close(L);
        return -3;
    }

    const int loadResult = luau_load(L, "=SporkEditor", bytecode, bytecodeSize, 0);
    free(bytecode);

    if (loadResult != 0) {
        appendError(L, output);
        lua_close(L);
        return -4;
    }

    const int callResult = lua_pcall(L, 0, LUA_MULTRET, 0);
    if (callResult != 0) {
        appendError(L, output);
        lua_close(L);
        return -5;
    }

    output = "Execução concluída.";
    lua_close(L);
    return 0;
}
