local M = {}

M.dotnvim_api_controller_template = function (name, namespace)
    return [[
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace ]] .. namespace .. [[
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    [ApiExplorerSettings(IgnoreApi = false)]
    public class ]] .. name .. [[: ControllerBase
    {
        public ]] .. name .. [[()
        {
        }       

        [HttpGet()]
        [Route('/')]
        [
            ProducesResponseType(StatusCodes.Status200OK,
            Type = typeof(String))
        ]
        public async Task<String>
        Get()
        {
            return Ok("Hello World")
        }
    }
}
]]
end

M.dotnvim_api_model_template = function (name, namespace)
    return [[
using System;

namespace ]] .. namespace .. [[ 
{
    public class ]] .. name .. [[ 
    {
        public Guid ID { get; set; }
        // Insert The rest of your columns
        // ...
    }
}
]]
end

M.dotnvim_api_mvc_controller_template = function (name, namespace)
    return [[
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace]] .. namespace .. [[ 
{
    public class ]] .. name .. [[Controller : ApiController
    {
        // GET api/<controller>
        [HttpGet()]
        [Route('/')]
        public IEnumerable<string> Get()
        {
            return new string[] { "value1", "value2" };
        }

        // GET api/<controller>/5
        [HttpGet()]
        [Route('/{id}')]
        public string Get([FromRoute] int id)
        {
            return "value";
        }

        // POST api/<controller>
        [HttpPost()]
        [Route('/{id}')]
        public void Post([FromBody] string value)
        {
        }

        // PUT api/<controller>/5
        [HttpPut()]
        [Route('/{id}')]
        public void Put([FromRoute] int id, [FromBody] string value)
        {
        }

        // DELETE api/<controller>/5
        [HttpPut()]
        [Route('/{id}')]
        public void Delete([FromRoute] int id)
        {
        }
    }
}
]]
end

M.dotnvim_razor_component_template = function(name, namespace)
        return [[
@page "/]] .. name:lower() .. [["
@namespace ]] .. namespace .. [[

<h3>]] .. name .. [[</h3>

<p>This is the ]] .. name .. [[ component.</p>

@code {
    // Your C# code for the component goes here
}
]]
    end


return M
