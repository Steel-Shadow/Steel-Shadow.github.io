---
layout:         post
title:          c++ 实现信号量 semaphore
subtitle:       
date:           2024-12-26
author:         Steel Shadow
# header-img:     img
# header-style:   text
mathjax:        true
tags:
    - c++
---

用 c++ 模拟一个简单的生产者、消费者问题。

```cpp
#include <bits/stdc++.h>
#include <cstdlib>
#include <iostream>
#include <mutex>
#include <ostream>
#include <thread>
#include <semaphore> // C++20
#include <vector>

constexpr int size = 10;

// 信号量实例，初始计数为 2，表示最多可以有两个线程同时进入临界区
std::binary_semaphore mutex(1);
std::counting_semaphore<size> empty_n(size);
std::counting_semaphore<size> product_n(0);

std::vector<int> data;

namespace Random {
std::random_device rd;
std::mt19937 gen(rd()); // Mersenne Twister 引擎
} // namespace Random

// 线程任务：每个线程都尝试获取信号量，做一些工作后释放信号量
void producer(int id) {
    while (true) {
        // 生产中
        std::uniform_int_distribution<> dis_time(1, 3);
        int time = dis_time(Random::gen);
        std::this_thread::sleep_for(std::chrono::seconds(time));

        std::uniform_int_distribution<> dis(-10, 10);
        int product = dis(Random::gen);

        empty_n.acquire();
        mutex.acquire();

        data.push_back(product);
        std::cout << "Producer " << id << " put product " << product << std::endl;

        product_n.release();
        mutex.release();
    }
}

void customer(int id) {
    while (true) {
        product_n.acquire();
        mutex.acquire();

        int product = data.back();
        data.pop_back();
        std::cout << "Customer " << id << " take product " << product << std::endl;

        empty_n.release();
        mutex.release();

        // 消费中
        std::uniform_int_distribution<> dis_time(1, 3);
        int time = dis_time(Random::gen);
        std::this_thread::sleep_for(std::chrono::seconds(time));
    }
}

int main() {
    int n_producer = 5;
    int n_customer = 7;

    std::vector<std::thread> producers;
    for (int i = 0; i < n_producer; ++i) {
        producers.emplace_back(producer, i);
    }
    std::vector<std::thread> customers;
    for (int i = 0; i < n_customer; ++i) {
        customers.emplace_back(customer, i);
    }

    for (auto &producer: producers) {
        producer.join();
    }
    for (auto &customer: customers) {
        customer.join();
    }
    
    return 0;
}
```
