import { Secret } from './secret';
import { Todo } from './todo';
import {Error} from './error';
import { Budget } from './budget';

export class Data{
    budget: Budget;
    secrets: Secret[];
    todo: Todo[];
    error: Error;
}