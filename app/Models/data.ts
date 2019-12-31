import { Secret } from './secret';
import { Todo } from './todo';
import {Error} from './error';

export class Data{
    secrets: Secret[];
    todo: Todo[];
    error: Error;
}