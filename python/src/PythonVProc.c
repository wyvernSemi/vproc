//=====================================================================
//
// PythonVProc.c                                     Date: 2024/01/24
//
// Copyright (c) 2024 Simon Southwell.
//
// This file is part of VProc.
//
// VProc is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// VProc is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with VProc. If not, see <http://www.gnu.org/licenses/>.
//
//=====================================================================

#include "PythonVProc.h"

// Define pointers to the external API functions
static wfunc_p      Vwrite;
static wbefunc_p    VwriteBE;
static rfunc_p      Vread;
static wbfunc_p     VburstWrite;
static wbbefunc_p   VburstWriteBE;
static rbfunc_p     VburstRead;
static tkfunc_p     Vtick;
static regirqfunc_p VregIrqPy;
static pyirqcb_p    PyIrqCB;
static pyfetchirq_p PyFetchIrq_;

// ------------------------------------------------------------
// Function to load VProc shared object and create bindings to
// the API functions
//
// Returns 0 on success, else 1
//
// ------------------------------------------------------------

static int BindToApiFuncs(void)
{
    void*   hdl  = dlopen("VProc.so", RTLD_NOW | RTLD_GLOBAL);

    if (hdl == NULL)
    {
        fprintf(stderr, "***ERROR: failed to load shared object\n");
        return 1;
    }

    if ((Vwrite = (wfunc_p)dlsym(hdl, "VWrite")) == NULL)
    {
        fprintf(stderr, "***ERROR: failed to find symbol VWrite\n");
        return 1;
    }
    
    if ((VwriteBE = (wfunc_p)dlsym(hdl, "VWriteBE")) == NULL)
    {
        fprintf(stderr, "***ERROR: failed to find symbol VWriteBE\n");
        return 1;
    }

    if ((Vread = (rfunc_p)dlsym(hdl, "VRead")) == NULL)
    {
        fprintf(stderr, "***ERROR: failed to find symbol VRead\n");
        return 1;
    }

    if ((VburstWrite = (wbfunc_p)dlsym(hdl, "VBurstWrite")) == NULL)
    {
        fprintf(stderr, "***ERROR: failed to find symbol VBurstWrite\n");
        return 1;
    }
    
    if ((VburstWriteBE = (wbbefunc_p)dlsym(hdl, "VBurstWriteBE")) == NULL)
    {
        fprintf(stderr, "***ERROR: failed to find symbol VBurstWriteBE\n");
        return 1;
    }

    if ((VburstRead = (rbfunc_p)dlsym(hdl, "VBurstRead")) == NULL)
    {
        fprintf(stderr, "***ERROR: failed to find symbol VBurstRead\n");
        return 1;
    }

    if ((Vtick = (tkfunc_p)dlsym(hdl, "VTick")) == NULL)
    {
        fprintf(stderr, "***ERROR: failed to find symbol VTick\n");
        return 1;
    }

    if ((VregIrqPy = (regirqfunc_p)dlsym(hdl, "VRegIrqPy")) == NULL)
    {
        fprintf(stderr, "***ERROR: failed to find symbol VRegIrqPy\n");
        return 1;
    }

    if ((PyIrqCB = (pyirqcb_p)dlsym(hdl, "PyIrqCB")) == NULL)
    {
        fprintf(stderr, "***ERROR: failed to find symbol PyIrqCB\n");
        return 1;
    }

    if ((PyFetchIrq_ = (pyfetchirq_p)dlsym(hdl, "PyFetchIrq")) == NULL)
    {
        fprintf(stderr, "***ERROR: failed to find symbol PyFetchIrq\n");
        return 1;
    }

    return 0;
}

// ------------------------------------------------------------
// Function to load and run a user supplied VUserMainX python
// function to match the node number (e.g. VUserMain0)
//
// Returns 0 on success
//
// ------------------------------------------------------------

int RunPython(const int node)
{
    PyObject *pName, *pModule, *pFunc;
    PyObject *pValue;
    char strbuf[DEFAULTSTRBUFSIZE];
    int status;
    int rtnval = 0;

    if (status = BindToApiFuncs())
    {
        return status;
    }

    // Register the Python interface interrupt callback function
    PyRegIrq(PyIrqCB, node);

    Py_Initialize();

    sprintf(strbuf, "VUserMain%d", node);

    pName = PyUnicode_DecodeFSDefault(strbuf);

    pModule = PyImport_Import(pName);
    Py_DECREF(pName);

    if (pModule != NULL)
    {
        pFunc = PyObject_GetAttrString(pModule, strbuf);

        if (pFunc && PyCallable_Check(pFunc))
        {
            pValue = PyObject_CallObject(pFunc, NULL);

            if (pValue != NULL)
            {
                rtnval =  PyLong_AsLong(pValue);
                Py_DECREF(pValue);
            }
            else
            {
                Py_DECREF(pFunc);
                Py_DECREF(pModule);
                PyErr_Print();
                fprintf(stderr,"***Error: RunPython() : Call failed\n");
                return 1;
            }
        }
        else
        {
            if (PyErr_Occurred())
            {
                PyErr_Print();
            }

            fprintf(stderr, "***Error: RunPython() : Cannot find function \"%s\"\n", strbuf);
        }

        Py_XDECREF(pFunc);
        Py_DECREF(pModule);
    }
    else
    {
        PyErr_Print();
        fprintf(stderr, "***Error: RunPython() : Failed to load \"%s\"\n", strbuf);
        return 1;
    }

    if (Py_FinalizeEx() < 0)
    {
        return 120;
    }

    return rtnval;
}

// Functions callable from Python

// ------------------------------------------------------------
// Extrnal print function alternative for when Python print
// output not displayed on the console (E.g. Questa on Linux).
// ------------------------------------------------------------

uint32_t PyPrint(const char* str)
{
    printf("%s\n", str);
    return 0;
}

// ------------------------------------------------------------
// VWrite wrapper function for Python
// ------------------------------------------------------------

uint32_t PyWrite (const uint32_t addr, const uint32_t data, const int delta, const uint32_t node)
{
    return Vwrite(addr, data, delta, node);
}

// ------------------------------------------------------------
// VWriteBE wrapper function for Python
// ------------------------------------------------------------

uint32_t PyWriteBE (const uint32_t addr, const uint32_t data, const uint32_t be, const int delta, const uint32_t node)
{
    return VwriteBE(addr, data, be, delta, node);
}

// ------------------------------------------------------------
// VRead wrapper function for Python
// ------------------------------------------------------------

uint32_t PyRead (const uint32_t addr, const int delta, const uint32_t node)
{
    uint32_t rdata;

    int status = Vread(addr, &rdata, delta, node);

    return (uint64_t)rdata;
}

// ------------------------------------------------------------
// VTick wrapper function for Python
// ------------------------------------------------------------

uint32_t PyTick (const uint32_t ticks, const uint32_t node)
{
    return Vtick(ticks, node);
}

// ------------------------------------------------------------
// VBurstWrite wrapper function for Python
// ------------------------------------------------------------

uint32_t PyBurstWrite (const uint32_t addr, void *data, const uint32_t len, const uint32_t node)
{
    return VburstWrite(addr, data, len, node);
}

// ------------------------------------------------------------
// VBurstWriteBE wrapper function for Python
// ------------------------------------------------------------

uint32_t PyBurstWriteBE (const uint32_t addr, void *data, const uint32_t len, uint32_t fbe, uint32_t lbe, const uint32_t node)
{
    return VburstWrite(addr, data, len, node);
}

// ------------------------------------------------------------
// VBurstRead wrapper function for Python
// ------------------------------------------------------------

uint32_t PyBurstRead (const uint32_t addr, void *data, const uint32_t len, const uint32_t node)
{
    return VburstRead(addr, data, len, node);
}

// ------------------------------------------------------------
// VRegIrq wrapper function for Python
// ------------------------------------------------------------

uint32_t PyRegIrq (const pPyIrqCB_t func, const uint32_t node)
{
    VregIrqPy(func, node);

    return 0;
}

// ------------------------------------------------------------
// PyFetchIrq wrapper function
// ------------------------------------------------------------

uint32_t PyFetchIrq (void *irq, const uint32_t node)
{
    PyFetchIrq_(irq, node);
}
