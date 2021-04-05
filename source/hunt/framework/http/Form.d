/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.http.Form;

import hunt.validation.ConstraintValidatorContext;
import hunt.validation.Valid;

import hunt.serialization.JsonSerializer;

interface Form : Valid
{
}

mixin template MakeForm()
{
    mixin MakeValid;
}

alias FormProperty = JsonProperty;
