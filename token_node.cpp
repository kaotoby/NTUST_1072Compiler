/*
 * Project 3
 * Author: B10630221 Chang-Ting Kao
 * Date: 2019/06/05
 */

#include "token_node.h"

namespace yy
{
    TokenNode::TokenNode(location loc)
    {
        lineNumber = loc.begin.line;
    }
    
} // namespace yy
