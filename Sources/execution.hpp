#pragma once
#include <string>

// Runs source in a fresh, isolated Luau VM owned by this application.
// Returns 0 on success; nonzero on compile/runtime failure.
// The optional output receives the diagnostic text.
int ExecuteScript(const std::string& source, std::string& output);
