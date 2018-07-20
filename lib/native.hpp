#pragma once

#include <cstddef>

namespace View393 {

const char VERSION[] =
#   include "./VERSION"
;
static constexpr std::size_t VERSION_LENGTH = sizeof(VERSION) - 1;

const char LONGDESCRIPTION[] =
#   include "./DESCRIPTION"
;
static constexpr std::size_t LONGDESCRIPTION_LENGTH = sizeof(LONGDESCRIPTION) - 1;

}
